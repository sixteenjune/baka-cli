local anim = require("lib.anim")

local M = {}

function M.run(arg)
	if arg[2] then
		anim.spin("rifling through its pockets")
	end
	local distro = require("modules.distro")
	distro.files(arg[2])
end

return M
