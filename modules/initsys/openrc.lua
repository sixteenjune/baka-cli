local exec = require("lib.exec")
local sudo = require("lib.sudo")

local M = {}

M.name = "openrc"

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
function M.list()
	local out = exec.capture("rc-status --servicelist")
	local services = {}
	for line in out:gmatch("[^\n]+") do
		local name, state = line:match("^%s*(%S+)%s*%[%s*(%a+)%s*%]")
		if name and state then
			table.insert(services, { name = name, state = state:lower() })
		end
	end
	table.sort(services, function(a, b) return a.name < b.name end)
	return services
end

function M.start(name)
	return sudo.run("rc-service " .. name .. " start", { label = name .. " start" })
end

function M.stop(name)
	return sudo.run("rc-service " .. name .. " stop", { label = name .. " stop" })
end

function M.restart(name)
	return sudo.run("rc-service " .. name .. " restart", { label = name .. " restart" })
end
function M.is_running(state)
	return state == "started"
end
function M.list_secondary()
	local out = exec.capture("ls /etc/init.d 2>/dev/null")
	local services = {}
	for name in out:gmatch("[^\n]+") do
		local status_out = exec.capture("rc-service " .. name .. " status 2>/dev/null")
		local state = status_out:match("status:%s*(%S+)")
		table.insert(services, { name = name, state = state and state:lower() or "unknown" })
	end
	table.sort(services, function(a, b) return a.name < b.name end)
	return services
end

M.secondary_label = "all /etc/init.d scripts"

return M
