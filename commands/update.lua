local M = {}

function M.run(arg)
	local distro = require("modules.distro")
	local ok, code = distro.update()
	if not ok then
		os.exit(code)
	end
end

return M
