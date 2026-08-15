local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")

local M = {}

function M.run(arg)
	local kernel = require("modules.kernel")

	format.heading("kernel build", icons.bolt)
	local ok, code, kver = kernel.build()
	if not ok then
		os.exit(code)
	end

	print()
	colors.success("built and installed " .. kver .. " -- the STRONGEST kernel now, obviously")

	print()
	format.heading("bootloader", icons.gear)
	local ok2, code2 = kernel.update_bootloader()
	if not ok2 then
		os.exit(code2)
	end
end

return M
