-- commands/why.lua
local anim = require("lib.anim")

local M = {}

function M.run(arg)
	if arg[2] then
		anim.spin("digging through dependencies")
	end
	local distro = require("modules.distro")
	distro.why(arg[2])
end

return M
