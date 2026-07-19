local sudo = require("lib.sudo")
local colors = require("lib.colors")

local M = {}

function M.run(arg)
	-- non-root steps go here, use colors.step(...) for output

	sudo.run("emerge -e --keep-going --with-bdeps=y --ask @world", {
		label = "rebuild",
	})
end

return M
