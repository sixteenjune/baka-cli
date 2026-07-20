-- modules/initsys/openrc.lua
local exec = require("lib.exec")

local M = {}

function M.status()
	local out = exec.capture("rc-status --servicelist")
	local running = 0
	local failed = {}

	for line in out:gmatch("[^\n]+") do
		local name, state = line:match("^%s*(%S+)%s*%[%s*(%a+)%s*%]")
		if name and state then
			local s = state:lower()
			if s == "started" then
				running = running + 1
			elseif s == "crashed" then
				table.insert(failed, name)
			end
		end
	end

	return {
		init_system = "openrc",
		running = running,
		failed = failed,
	}
end

return M
