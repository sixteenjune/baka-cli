-- commands/rebuild.lua
local M = {}

function M.run(arg)
	-- required lazily so `commands.init` (the registry) can load this file
	-- without needing a distro already configured
	local distro = require("modules.distro")
	local ok, code = distro.rebuild()
	if not ok then
		os.exit(code)
	end
end

return M
