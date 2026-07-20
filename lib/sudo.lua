-- lib/sudo.lua
-- Privilege escalation wrapper. Reads which tool to use (doas or sudo)
-- from config (set via `baka init`), defaulting to doas.
--
-- doas/sudo print their own password prompt straight to /dev/tty (so we
-- can't restyle that exact line), but we frame it with a styled banner
-- so it doesn't feel like a raw, out-of-place prompt. Ctrl+C during the
-- elevated command is reported with its real exit code (130) via
-- lib/exec's run_live, consistently whether you're using doas or sudo.

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

--- Run `cmd` elevated. opts.label is used in the success/fail message.
--- Returns ok (boolean), code (number). Does not exit on failure.
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

--- Same as run(), but exits the process (with the real exit code) on
--- failure. Use for steps where continuing afterwards wouldn't make
--- sense (e.g. sync before update).
function M.run_or_exit(cmd, opts)
	local ok, code = M.run(cmd, opts)
	if not ok then
		os.exit(code)
	end
	return ok, code
end

return M
