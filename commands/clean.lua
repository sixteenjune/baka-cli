-- commands/clean.lua
local M = {}

function M.run(arg)
	local distro = require("modules.distro")
	local ok, code = distro.clean()
	if not ok then
		os.exit(code)
	end
end

return M
