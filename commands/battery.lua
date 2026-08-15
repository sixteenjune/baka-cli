local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")
local power = require("lib.power")

local M = {}

local function read(path)
	local out = exec.capture("cat " .. path .. " 2>/dev/null"):gsub("%s+$", "")
	return out
end

local function batteries()
	local out = exec.capture("ls -d /sys/class/power_supply/BAT* 2>/dev/null")
	local list = {}
	for path in out:gmatch("[^\n]+") do
		table.insert(list, path)
	end
	return list
end

function M.run(arg)
	anim.spin("checking your battery's will to live")

	format.heading("battery", icons.bolt)

	local bats = batteries()
	if #bats == 0 then
		colors.warn("no battery found -- desktop, or it's hiding")
		return
	end

	for _, path in ipairs(bats) do
		local name = path:match("([^/]+)$")
		local status = read(path .. "/status")
		local capacity = read(path .. "/capacity")
		local full_now = tonumber(read(path .. "/energy_full")) or tonumber(read(path .. "/charge_full"))
		local full_design = tonumber(read(path .. "/energy_full_design")) or tonumber(read(path .. "/charge_full_design"))

		local health = "unknown"
		if full_now and full_design and full_design > 0 then
			health = string.format("%.1f%% of design capacity", (full_now / full_design) * 100)
		end

		local cycles = read(path .. "/cycle_count")
		if cycles == "" or cycles == "0" then
			cycles = "unknown"
		end

		local rows = {
			{ "status",   status ~= "" and status or "unknown" },
			{ "capacity", capacity ~= "" and (capacity .. "%") or "unknown" },
			{ "health",   health },
			{ "cycles",   cycles },
		}
		local start_thresh = read(path .. "/charge_control_start_threshold")
		local end_thresh = read(path .. "/charge_control_end_threshold")
		if start_thresh ~= "" and end_thresh ~= "" then
			table.insert(rows, { "charge limit", start_thresh .. "% - " .. end_thresh .. "%" })
		end

		if #bats > 1 then
			format.heading(name, icons.bolt)
		end
		format.kv_list(rows)
		print()
	end

	format.heading("power", icons.gear)
	format.kv_list({
		{ "manager", power.detect_tool() },
	})
end

return M
