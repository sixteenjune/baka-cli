
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")

local M = {}
local function test_ipv4()
	local result = exec.capture("ping -c 1 -W 1 8.8.8.8 2>/dev/null")
	return result ~= "" and not result:match("100%% packet loss")
end

local function test_ipv6()
	local result = exec.capture("ping6 -c 1 -W 1 2001:4860:4860::8888 2>/dev/null")
	return result ~= "" and not result:match("100%% packet loss")
end
local function test_udp()
	local result = exec.capture("timeout 2 bash -c 'echo -n | nc -u -w1 8.8.8.8 53' 2>/dev/null")
	return result ~= ""
end
local function test_tcp()
	local result = exec.capture("timeout 3 bash -c 'exec 3<>/dev/tcp/8.8.8.8/80' 2>/dev/null && echo success")
	return result:match("success") ~= nil
end
local function test_icmp()
	return test_ipv4()
end
local function test_dns()
	local result = exec.capture("timeout 2 dig @8.8.8.8 google.com +short 2>/dev/null")
	return result ~= "" and not result:match("connection timed out")
end
local function test_doh()
	local result = exec.capture(
		"timeout 5 curl -sS 'https://dns.google/resolve?name=google.com' 2>/dev/null | grep -q 'google.com'"
	)
	return exec.ok(result)
end
local function test_websocket()
	local result = exec.capture(
		"timeout 3 curl -i -N -H 'Connection: Upgrade' -H 'Upgrade: websocket' 'http://echo.websocket.org' 2>/dev/null | head -1"
	)
	return result ~= ""
end
local function test_tls()
	local result = exec.capture("timeout 3 curl -sS -I https://www.google.com 2>/dev/null | head -1")
	return result:match("HTTP") ~= nil
end
local function check_dns_leak()
	local result = exec.capture("cat /etc/resolv.conf 2>/dev/null | grep -E '^nameserver' | head -3")
	local resolvers = {}
	for line in result:gmatch("[^\n]+") do
		local ip = line:match("nameserver%s+([%d.%da-f:]+)")
		if ip then
			table.insert(resolvers, ip)
		end
	end
	return resolvers
end
local function render_test(name, available)
	local icon = available and colors.green .. icons.check .. colors.reset or colors.red .. icons.cross .. colors.reset
	local status = available and colors.green .. "available" .. colors.reset or colors.red .. "blocked" .. colors.reset
	return { name, icon .. "  " .. status }
end

function M.run(arg)
	anim.spin("inspecting your network")

	print()
	format.heading("network protocol inspection", icons.wifi)
	print()
	local results = {
		render_test("IPv4",      test_ipv4()),
		render_test("IPv6",      test_ipv6()),
		render_test("TCP",       test_tcp()),
		render_test("UDP",       test_udp()),
		render_test("ICMP",      test_icmp()),
		render_test("DNS",       test_dns()),
		render_test("DoH",       test_doh()),
		render_test("TLS/HTTPS", test_tls()),
		render_test("WebSocket", test_websocket()),
	}

	format.table({ "protocol", "status" }, results)

	print()
	format.heading("dns configuration", icons.info)
	local resolvers = check_dns_leak()
	if #resolvers > 0 then
		colors.step("configured resolvers:")
		for _, resolver in ipairs(resolvers) do
			print("  " .. resolver)
		end
	else
		colors.warn("no nameservers found in /etc/resolv.conf")
	end
	print()
	local all_ok = true
	for _, result in ipairs(results) do
		if result[2]:match(icons.cross) then
			all_ok = false
			break
		end
	end

	if all_ok then
		colors.success("all protocols available -- network looks clean")
	else
		colors.warn("some protocols are blocked or unavailable -- check firewall/ISP")
	end
end

return M
