local colors = require("lib.colors")

local M = {}

--- run a command under doas with a styled banner around it
--- @param cmd string  the shell command to run (without "doas ")
--- @param opts table|nil  { label = "rebuild" }
function M.run(cmd, opts)
	opts = opts or {}
	local label = opts.label or "command"

	colors.info(colors.bold .. "requesting root privileges" .. colors.reset)
	colors.step("running: " .. colors.grey .. cmd .. colors.reset)

	local full = "doas " .. cmd
	local ok = os.execute(full)

	if ok then
		colors.success(label .. " completed successfully")
	else
		colors.error(label .. " failed")
		os.exit(1)
	end

	return ok
end

return M
