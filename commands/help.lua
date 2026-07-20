-- commands/help.lua
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")

local M = {}

local entries = {
	{ name = "init",     args = "",       desc = "first-time setup (or re-run to tweak settings)" },
	{ name = "help",     args = "",       desc = "show this menu, because you clearly need it" },
	{ name = "status",   args = "",       desc = "distro, services, hardware, vpn -- one glance" },
	{ name = "rebuild",  args = "",       desc = "rebuild the whole system, the STRONGEST way" },
	{ name = "update",   args = "",       desc = "sync + update packages" },
	{ name = "clean",    args = "",       desc = "clear out old packages and orphans" },
	{ name = "backup",   args = "",       desc = "tar up your configs into ~/backups/" },
	{ name = "why",      args = "<pkg>",  desc = "what depends on <pkg>" },
	{ name = "files",    args = "<pkg>",  desc = "what files <pkg> owns" },
	{ name = "ports",    args = "",       desc = "what's listening, and what's holding it open" },
	{ name = "network",  args = "",       desc = "a prettier `ip a`, plus vpn status" },
	{ name = "storage",  args = "",       desc = "disk + swap usage breakdown, largest items in ~" },
	{ name = "kernel",   args = "",       desc = "build + install from /usr/src/linux, update bootloader" },
	{ name = "services", args = "",       desc = "arrow-key start/stop menu for systemd/openrc" },
	{ name = "temp",     args = "",       desc = "thermal zones, governor, turbo, power manager" },
	{ name = "battery",  args = "",       desc = "capacity, health, cycles, charge thresholds" },
	{ name = "cpu",      args = "",       desc = "live per-core usage + temp, min/avg/p95/max" },
	{ name = "doctor",   args = "",       desc = "check baka's own setup for problems" },
}

function M.run(arg)
	format.heading("baka -- the STRONGEST cli, obviously", icons.snowflake)
	print()
	print(colors.dim .. "usage: baka <command> [args]" .. colors.reset)
	print()

	local rows = {}
	for _, e in ipairs(entries) do
		local usage = e.args ~= "" and (e.name .. " " .. e.args) or e.name
		table.insert(rows, { colors.blue .. usage .. colors.reset, e.desc })
	end
	format.table({ "command", "description" }, rows)

	print()
	colors.step("config lives at ~/.config/baka/baka.conf -- `baka init` to change it")
end

return M
