-- commands/temp.lua
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")
local power = require("lib.power")

local M = {}

function M.run(arg)
	anim.spin("checking how hot you're running")

	format.heading("temperatures", icons.bolt)
	local list = power.zones()
	if #list == 0 then
		colors.warn("no thermal zones found -- kernel might not expose them here")
	else
		local rows = {}
		for _, z in ipairs(list) do
			table.insert(rows, { z.label, format.temp_colored(z.celsius) })
		end
		format.table({ "zone", "temp" }, rows)
	end

	print()
	format.heading("power", icons.gear)
	format.kv_list({
		{ "governor", power.governor() },
		{ "turbo",    power.turbo_status() },
		{ "manager",  power.detect_tool() },
	})
end

return M
