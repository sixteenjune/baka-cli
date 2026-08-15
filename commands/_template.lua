
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")
local sudo = require("lib.sudo")

local M = {}

function M.run(arg)
	anim.spin("doing the thing")

	format.heading("section title", icons.gear)
	colors.step("a step worth mentioning")

	colors.success("done -- obviously")
end

return M
