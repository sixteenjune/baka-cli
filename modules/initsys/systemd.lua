-- modules/initsys/systemd.lua
local exec = require("lib.exec")

local M = {}

function M.status()
	local failed_out = exec.capture("systemctl --failed --no-legend --plain")
	local failed = {}
	for line in failed_out:gmatch("[^\n]+") do
		local name = line:match("^(%S+)")
		if name then table.insert(failed, name) end
	end

	local running_out = exec.capture(
		"systemctl list-units --type=service --state=running --no-legend --plain"
	)
	local running = 0
	for _ in running_out:gmatch("[^\n]+") do
		running = running + 1
	end

	return {
		init_system = "systemd",
		running = running,
		failed = failed,
	}
end

return M
