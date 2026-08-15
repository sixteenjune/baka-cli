
local M = {}
function M.ok(status)
	if type(status) == "boolean" then
		return status
	end
	if type(status) == "number" then
		return status == 0
	end
	return false
end
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
function M.capture(cmd)
	local handle = io.popen(cmd .. " 2>/dev/null")
	if not handle then
		return ""
	end
	local result = handle:read("*a") or ""
	handle:close()
	return result
end
function M.capture_all(cmd)
	local handle = io.popen(cmd .. " 2>&1")
	if not handle then
		return ""
	end
	local result = handle:read("*a") or ""
	handle:close()
	return result
end
function M.has(bin)
	local status = os.execute("command -v " .. bin .. " >/dev/null 2>&1")
	return M.ok(status)
end
function M.path_exists(path)
	local status = os.execute('test -e "' .. path .. '" 2>/dev/null')
	return M.ok(status)
end

return M
