-- modules/initsys/systemd.lua
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

--- Every service unit systemd knows about, loaded or not, with its
--- current active state. Used by `baka services` to build the menu.
--- @return table  list of { name, state } where state is "active"/"inactive"/"failed"/...
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

--- Is this service's state one the menu should render as "running"?
function M.is_running(state)
	return state == "active"
end

--- --user scope units -- a genuinely separate manager from the system
--- one, over the invoking user's own session bus. M.list() above can
--- never see these no matter how it's queried; this is a different
--- systemctl invocation entirely, not a filter on the same data.
--- Toggled via 't' in `baka services` rather than merged into M.list(),
--- so it's clear which scope you're looking at.
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

-- Deliberately NOT elevated -- see the doc comment on list_secondary.
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
