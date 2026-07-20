-- commands/network.lua
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")

local M = {}

local function parse_interfaces()
	local output = exec.capture("ip addr show")
	local interfaces = {}
	local current = nil

	for line in output:gmatch("[^\n]+") do
		local name, flags = line:match("^%d+:%s+(%S+):%s*<(.-)>")
		if name then
			name = name:gsub("@.*", "")
			-- flags decide up/down, not the "state" field -- loopback and
			-- some virtual interfaces report `state UNKNOWN` even though
			-- their flags clearly include UP
			local up = flags:find("UP") ~= nil
			current = {
				name = name,
				state = up and "UP" or "DOWN",
				ipv4 = {},
				mac = "-",
			}
			table.insert(interfaces, current)
		elseif current then
			local mac = line:match("link/%S+%s+(%S+)")
			if mac and mac ~= "00:00:00:00:00:00" then
				current.mac = mac
			end
			local ip4 = line:match("^%s*inet%s+(%S+)")
			if ip4 then
				table.insert(current.ipv4, ip4)
			end
		end
	end

	return interfaces
end

function M.run(arg)
	anim.spin("fetching network details")

	format.heading("network interfaces", icons.wifi)
	print()

	local interfaces = parse_interfaces()
	local rows = {}
	for _, iface in ipairs(interfaces) do
		local state_str = iface.state == "UP"
			and (colors.green .. "up" .. colors.reset)
			or (colors.red .. "down" .. colors.reset)
		local ips = #iface.ipv4 > 0
			and table.concat(iface.ipv4, ", ")
			or (colors.grey .. "-" .. colors.reset)
		table.insert(rows, { iface.name, state_str, ips, iface.mac })
	end

	if #rows == 0 then
		colors.warn("no interfaces found -- are you even plugged in?")
	else
		format.table({ "iface", "state", "address", "mac" }, rows)
	end

	print()
	format.heading("vpn", icons.link)
	local vpn = require("modules.vpn")
	format.print_vpn(vpn.status())
end

return M
