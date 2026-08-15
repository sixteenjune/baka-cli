
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local tty = require("lib.tty")
local power = require("lib.power")

local M = {}
local function read_stat()
	local out = exec.capture("cat /proc/stat")
	local overall = nil
	local cores = {}
	local max_idx = -1

	for line in out:gmatch("[^\n]+") do
		local label, rest = line:match("^(cpu%d*)%s+(.*)$")
		if label then
			local nums = {}
			for n in rest:gmatch("%d+") do
				table.insert(nums, tonumber(n))
			end
			local user, nice, system, idle = nums[1] or 0, nums[2] or 0, nums[3] or 0, nums[4] or 0
			local iowait, irq, softirq, steal = nums[5] or 0, nums[6] or 0, nums[7] or 0, nums[8] or 0
			local idle_all = idle + iowait
			local total = user + nice + system + idle + iowait + irq + softirq + steal
			local entry = { idle_all = idle_all, total = total }

			if label == "cpu" then
				overall = entry
			else
				local idx = tonumber(label:match("%d+"))
				if idx then
					cores[idx] = entry
					if idx > max_idx then
						max_idx = idx
					end
				end
			end
		end
	end

	return overall, cores, max_idx + 1
end
local function usage_pct(prev, cur)
	if not prev or not cur then
		return 0
	end
	local total_delta = cur.total - prev.total
	local idle_delta = cur.idle_all - prev.idle_all
	if total_delta <= 0 then
		return 0
	end
	local pct = 100 * (total_delta - idle_delta) / total_delta
	if pct < 0 then pct = 0 end
	if pct > 100 then pct = 100 end
	return pct
end

local function percentile(list, p)
	if #list == 0 then
		return 0
	end
	local sorted = {}
	for i, v in ipairs(list) do
		sorted[i] = v
	end
	table.sort(sorted)
	local idx = math.ceil(p * #sorted)
	if idx < 1 then idx = 1 end
	if idx > #sorted then idx = #sorted end
	return sorted[idx]
end

local function stats(list)
	if #list == 0 then
		return { min = 0, avg = 0, p95 = 0, max = 0 }
	end
	local sum, lo, hi = 0, math.huge, -math.huge
	for _, v in ipairs(list) do
		sum = sum + v
		if v < lo then lo = v end
		if v > hi then hi = v end
	end
	return { min = lo, avg = sum / #list, p95 = percentile(list, 0.95), max = hi }
end

local function pct_text(p)
	return format.pct_colored(p, string.format("%5.1f%%", p))
end

local function temp_text(c)
	return format.temp_colored(c, string.format("%5.1fC", c))
end

local function draw(core_pcts, ncores, overall_pct, overall_stats, temp_now, temp_stats, samples)
	io.write("\27[2J\27[H")

	format.heading("cpu monitor", icons.cpu)
	print(colors.dim .. "live, updates every 1s -- q / esc to stop" .. colors.reset)
	print()

	if ncores > 0 then
		for i = 0, ncores - 1, 2 do
			local line = "  " .. string.format("core%-2d  %s", i, pct_text(core_pcts[i] or 0))
			if i + 1 < ncores then
				line = line .. "      " .. string.format("core%-2d  %s", i + 1, pct_text(core_pcts[i + 1] or 0))
			end
			print(line)
		end
		print()
	end

	local rows = {
		{
			"cpu",
			pct_text(overall_pct),
			pct_text(overall_stats.min),
			pct_text(overall_stats.avg),
			pct_text(overall_stats.p95),
			pct_text(overall_stats.max),
		},
	}
	if temp_now then
		table.insert(rows, {
			"temp",
			temp_text(temp_now),
			temp_text(temp_stats.min),
			temp_text(temp_stats.avg),
			temp_text(temp_stats.p95),
			temp_text(temp_stats.max),
		})
	end
	format.table({ "", "now", "min", "avg", "p95", "max" }, rows)

	print()
	print(colors.dim .. samples .. " sample(s)" .. colors.reset)
end

function M.run(arg)
	if not tty.is_tty() then
		colors.error("baka cpu needs an actual terminal for the live view")
		os.exit(1)
	end

	local overall_history = {}
	local temp_history = {}
	local samples = 0

	local prev_overall, prev_cores = read_stat()

	tty.raw_on()

	while true do
		local key = tty.wait_key(10) -- ~1s tick, also the quit-key check
		if key == "q" or key == "esc" or key == "ctrl-c" then
			break
		end

		local cur_overall, cur_cores, ncores = read_stat()

		local overall_pct = usage_pct(prev_overall, cur_overall)
		local core_pcts = {}
		for i = 0, ncores - 1 do
			core_pcts[i] = usage_pct(prev_cores[i], cur_cores[i])
		end

		table.insert(overall_history, overall_pct)
		samples = samples + 1

		local temp_now = power.primary_temp()
		if temp_now then
			table.insert(temp_history, temp_now)
		end

		draw(core_pcts, ncores, overall_pct, stats(overall_history), temp_now, stats(temp_history), samples)

		prev_overall, prev_cores = cur_overall, cur_cores
	end

	tty.restore()
	io.write("\27[2J\27[H")
	io.flush()
	colors.success("stopped watching -- " .. samples .. " sample(s) collected")
end

return M
