local sudo = require("lib.sudo")

local M = {}

function M.run(arg)
	sudo.run("emerge -e --keep-going --with-bdeps=y --ask @world", {
		label = "rebuild",
	})
end

return M
