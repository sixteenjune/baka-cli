
local colors = require("lib.colors")
local icons = require("lib.icons")
local exec = require("lib.exec")
local config = require("lib.config")

local M = {}

local function escalation_tool()
	local cfg = config.load()
	if cfg.escalation == "sudo" then
		return "sudo"
	end
	return "doas"
end
function M.run(cmd, opts)
	opts = opts or {}
	local label = opts.label or "command"
	local tool = escalation_tool()

	colors.neon_tag(icons.lock .. " requesting root privileges (" .. tool .. ")")
	colors.step("running: " .. colors.grey .. cmd .. colors.reset)

	local ok, code = exec.run_live(tool .. " " .. cmd)

	if ok then
		colors.success(label .. " completed successfully, obviously~")
	elseif code == 130 then
		colors.error(label .. " interrupted (ctrl+c, exit code " .. code .. ") -- fine, be that way")
	else
		colors.error(label .. " failed (exit code " .. code .. ")")
	end

	return ok, code
end
function M.run_or_exit(cmd, opts)
	local ok, code = M.run(cmd, opts)
	if not ok then
		os.exit(code)
	end
	return ok, code
end
function M.run_unprivileged(cmd, opts)
	opts = opts or {}
	local label = opts.label or "command"

	local ok, code = exec.run_live(cmd)

	if ok then
		colors.success(label .. " completed successfully, obviously~")
	elseif code == 130 then
		colors.error(label .. " interrupted (ctrl+c, exit code " .. code .. ") -- fine, be that way")
	else
		colors.error(label .. " failed (exit code " .. code .. ")")
	end

	return ok, code
end

return M
