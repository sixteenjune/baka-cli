local M = {}
local colors = require("lib.colors")

local function run_cmd(cmd)
	local res, exit_type, exit_code = os.execute(cmd)
	local success = (res == true or res == 0)

	if not success then
		local code = (type(res) == "number") and res or (exit_code or "unknown")
		print()
		colors.error("operation failed or interrupted (exit code: " .. code .. "). exiting~")
		os.exit(1)
	end
end

function M.run(arg)
	colors.info("requesting root privileges")
	colors.step("running: emerge --sync")
	run_cmd("doas emerge --sync")
	colors.success("sync completed successfully")

	print()
	colors.info("requesting root privileges")
	colors.step("running: emerge -uDNa @world")
	run_cmd("doas emerge -uDNa @world")
	colors.success("update completed successfully")
end

return M
