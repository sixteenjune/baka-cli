local M = {}

local function config_dir()
	local xdg = os.getenv("XDG_CONFIG_HOME")
	if xdg and xdg ~= "" then
		return xdg .. "/baka"
	end
	return os.getenv("HOME") .. "/.config/baka"
end

local function config_path()
	return config_dir() .. "/baka.conf"
end

function M.exists()
	local f = io.open(config_path(), "r")
	if f then
		f:close()
		return true
	end
	return false
end

function M.load()
	local data = {}
	local f = io.open(config_path(), "r")
	if not f then
		return data
	end
	for line in f:lines() do
		local k, v = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if k then
			data[k] = v
		end
	end
	f:close()
	return data
end

function M.save(data)
	os.execute('mkdir -p "' .. config_dir() .. '"')
	local f = io.open(config_path(), "w")
	if not f then
		error("could not write config file at " .. config_path())
	end
	local keys = {}
	for k in pairs(data) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in ipairs(keys) do
		f:write(k .. "=" .. tostring(data[k]) .. "\n")
	end
	f:close()
end

function M.path()
	return config_path()
end

return M
