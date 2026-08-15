
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")

local M = {}
local PROVIDERS = {
	{ name = "Linode (HTTPS)",     url = "https://speed.linode.com/100MB-debian.bin",        size_mb = 100 },
	{ name = "Google (HTTPS)",     url = "https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png", size_mb = 0.3 },
	{ name = "Cloudflare",         url = "https://speed.cloudflare.com/__down?bytes=52428800", size_mb = 50 },
	{ name = "Comcast FastPath",   url = "http://speedtest.fios.verizon.net/speedtest/speedtest/random4000x4000.jpg", size_mb = 1 },
}
local function test_provider(name, url)
	local cmd = string.format(
		'curl -sS -o /dev/null -w "%%{speed_download}" -m 15 "%s" 2>/dev/null',
		url
	)
	local result = exec.capture(cmd)
	local bytes_per_sec = tonumber(result) or 0
	if bytes_per_sec == 0 then
		return nil
	end
	local mbps = bytes_per_sec * 8 / 1000000
	return mbps
end
local function calculate_stats(values)
	if #values == 0 then
		return { min = 0, avg = 0, p95 = 0, max = 0 }
	end

	table.sort(values)

	local min, max = values[1], values[#values]
	local sum = 0
	for _, v in ipairs(values) do
		sum = sum + v
	end
	local avg = sum / #values
	local p95_idx = math.ceil(0.95 * #values)
	if p95_idx < 1 then p95_idx = 1 end
	local p95 = values[p95_idx]

	return { min = min, avg = avg, p95 = p95, max = max }
end
local function spawn_test(provider, output_file)
	local cmd = string.format(
		'echo "%s" > "%s" && curl -sS -o /dev/null -w "%%{speed_download}" -m 15 "%s" >> "%s" 2>/dev/null || echo "0" >> "%s"',
		provider.name, output_file, provider.url, output_file, output_file
	)
	os.execute(cmd .. " &")
end

function M.run(arg)
	anim.spin("running speed tests across multiple providers")
	local temp_files = {}
	local pids = {}
	for i, provider in ipairs(PROVIDERS) do
		local tmpfile = os.tmpname()
		temp_files[i] = tmpfile
		spawn_test(provider, tmpfile)
	end
	local timeout_start = os.time()
	local timeout_secs = 60
	local all_done = false

	while not all_done and (os.time() - timeout_start) < timeout_secs do
		all_done = true
		for i = 1, #PROVIDERS do
			local f = io.open(temp_files[i], "r")
			if f then
				local content = f:read("*a")
				f:close()
				local lines = 0
				for _ in content:gmatch("[^\n]+") do
					lines = lines + 1
				end
				if lines < 2 then
					all_done = false
				end
			else
				all_done = false
			end
		end
		if not all_done then
			os.execute("sleep 0.5")
		end
	end
	local results = {}
	local valid_speeds = {}

	for i, provider in ipairs(PROVIDERS) do
		local f = io.open(temp_files[i], "r")
		local mbps = nil
		if f then
			local name = f:read("*l")
			local speed_bytes = tonumber(f:read("*l") or "0")
			f:close()
			if speed_bytes > 0 then
				mbps = speed_bytes * 8 / 1000000
				table.insert(valid_speeds, mbps)
			end
		end
		table.insert(results, { name = provider.name, mbps = mbps })
		os.remove(temp_files[i])
	end
	print()
	format.heading("speedtest results", icons.bolt)
	print()
	format.heading("by provider", icons.info)
	local provider_rows = {}
	for _, result in ipairs(results) do
		if result.mbps then
			table.insert(provider_rows, {
				result.name,
				format.speed_colored(result.mbps, string.format("%.2f Mbps", result.mbps)),
			})
		else
			table.insert(provider_rows, {
				result.name,
				colors.grey .. "timeout / unavailable" .. colors.reset,
			})
		end
	end
	format.table({ "provider", "speed" }, provider_rows)
	if #valid_speeds > 0 then
		print()
		local stats = calculate_stats(valid_speeds)
		format.heading("aggregate statistics", icons.cpu)

		local stats_rows = {
			{
				"min",
				format.speed_colored(stats.min, string.format("%.2f Mbps", stats.min)),
			},
			{
				"avg",
				format.speed_colored(stats.avg, string.format("%.2f Mbps", stats.avg)),
			},
			{
				"p95",
				format.speed_colored(stats.p95, string.format("%.2f Mbps", stats.p95)),
			},
			{
				"max",
				format.speed_colored(stats.max, string.format("%.2f Mbps", stats.max)),
			},
		}
		format.table({ "metric", "value" }, stats_rows)

		print()
		if stats.avg >= 50 then
			colors.success(string.format("excellent connection (%.1f Mbps average)", stats.avg))
		elseif stats.avg >= 10 then
			colors.info(string.format("good connection (%.1f Mbps average)", stats.avg))
		else
			colors.warn(string.format("slow connection (%.1f Mbps average) -- something's up", stats.avg))
		end
	else
		print()
		colors.error("no successful tests -- check your connection or try again")
		os.exit(1)
	end
end

return M
