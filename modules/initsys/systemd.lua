local exec = require("lib.exec")
local sudo = require("lib.sudo")

local M = {}

M.name = "systemd"

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
function M.list()
	local out = exec.capture("systemctl list-units --type=service --all --no-legend --plain")
	local services = {}
	for line in out:gmatch("[^\n]+") do
		local tokens = {}
		for tok in line:gmatch("%S+") do
			table.insert(tokens, tok)
			if #tokens >= 4 then break end
		end
		local name, active = tokens[1], tokens[3]
		if name then
			table.insert(services, { name = name, state = active or "unknown" })
		end
	end
	table.sort(services, function(a, b) return a.name < b.name end)
	return services
end

function M.start(name)
	return sudo.run("systemctl start " .. name, { label = name .. " start" })
end

function M.stop(name)
	return sudo.run("systemctl stop " .. name, { label = name .. " stop" })
end

function M.restart(name)
	return sudo.run("systemctl restart " .. name, { label = name .. " restart" })
end
function M.is_running(state)
	return state == "active"
end
function M.list_secondary()
	local out = exec.capture("systemctl --user list-units --type=service --all --no-legend --plain")
	local services = {}
	for line in out:gmatch("[^\n]+") do
		local tokens = {}
		for tok in line:gmatch("%S+") do
			table.insert(tokens, tok)
			if #tokens >= 4 then break end
		end
		local name, active = tokens[1], tokens[3]
		if name then
			table.insert(services, { name = name, state = active or "unknown" })
		end
	end
	table.sort(services, function(a, b) return a.name < b.name end)
	return services
end

M.secondary_label = "--user units"
function M.start_secondary(name)
	return sudo.run_unprivileged("systemctl --user start " .. name, { label = name .. " start (user)" })
end

function M.stop_secondary(name)
	return sudo.run_unprivileged("systemctl --user stop " .. name, { label = name .. " stop (user)" })
end

function M.restart_secondary(name)
	return sudo.run_unprivileged("systemctl --user restart " .. name, { label = name .. " restart (user)" })
end

return M
