-- lib/exec.lua
-- Shell execution helpers.
--
-- The tricky bit: Lua 5.1's os.execute() returns a raw, platform-specific
-- wait-status integer (not a clean exit code), while Lua 5.2+ returns
-- true/nil/false plus "exit"/"signal" and a code. Decoding the 5.1 raw
-- status by hand is fiddly and not fully portable. Instead, M.run_live()
-- sidesteps this entirely: it lets the *shell* capture its own $? into a
-- temp file after the command finishes. This works identically on every
-- Lua version, and -- importantly -- the command still runs with a real,
-- inherited TTY (so doas/sudo password prompts and emerge/pacman's
-- progress output behave exactly like running it directly in your shell).
--
-- This also means Ctrl+C is reported correctly and consistently: a
-- foreground child killed by SIGINT makes the shell report exit code 130
-- (128 + signal 2), the same on every distro and every Lua version.

local M = {}

--- Normalize any bare os.execute()-style return into a boolean.
--- Only used for cheap yes/no checks (M.has, M.path_exists) where the
--- exact exit code doesn't matter.
function M.ok(status)
	if type(status) == "boolean" then
		return status
	end
	if type(status) == "number" then
		return status == 0
	end
	return false
end

--- Run a command with a real, inherited TTY (so passwords prompts and
--- interactive progress bars behave normally), and return its *actual*
--- numeric exit code reliably across Lua versions.
--- @return boolean ok, number code
function M.run_live(cmd)
	local status_file = os.tmpname()
	os.execute(cmd .. " ; echo $? > " .. status_file)

	local code = 1
	local f = io.open(status_file, "r")
	if f then
		code = tonumber(f:read("*l")) or 1
		f:close()
	end
	os.remove(status_file)

	return code == 0, code
end

--- Run a command and capture its stdout as a string. Stderr is discarded.
--- Returns "" on failure to even spawn the command.
function M.capture(cmd)
	local handle = io.popen(cmd .. " 2>/dev/null")
	if not handle then
		return ""
	end
	local result = handle:read("*a") or ""
	handle:close()
	return result
end

--- Run a command and capture combined stdout+stderr.
function M.capture_all(cmd)
	local handle = io.popen(cmd .. " 2>&1")
	if not handle then
		return ""
	end
	local result = handle:read("*a") or ""
	handle:close()
	return result
end

--- Check whether a binary exists on PATH.
function M.has(bin)
	local status = os.execute("command -v " .. bin .. " >/dev/null 2>&1")
	return M.ok(status)
end

--- Check whether a path exists on disk.
function M.path_exists(path)
	local status = os.execute('test -e "' .. path .. '" 2>/dev/null')
	return M.ok(status)
end

return M
