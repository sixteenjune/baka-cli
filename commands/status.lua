-- commands/status.lua
local config = require("lib.config")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local exec = require("lib.exec")
local anim = require("lib.anim")

local M = {}

local function trimmed(cmd)
	local out = exec.capture(cmd):gsub("%s+$", "")
	return out
end

local function cpu_model()
	local model = trimmed("lscpu 2>/dev/null | grep 'Model name' | sed 's/.*:[ \\t]*//'")
	if model ~= "" then
		return model
	end
	return trimmed("grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'")
end

local function memory_usage()
	local out = trimmed("free -h | awk '/Mem:/ {print $3 \" / \" $2}'")
	return out ~= "" and out or "unknown"
end

local function uptime()
	local out = trimmed("uptime -p"):gsub("^up ", "")
	return out ~= "" and out or "unknown"
end

--- Distro-specific installed package count. Only queries the backend
--- that's actually configured -- never both, and never hard-fails if
--- distro isn't set yet (status should still show what it can).
local function package_info(cfg)
	if cfg.distro == "gentoo" then
		local gentoo = require("modules.distro.gentoo")
		return gentoo.package_count(), "gentoo"
	elseif cfg.distro == "arch" then
		local arch = require("modules.distro.arch")
		return arch.package_count(), "arch"
	end
	return nil, nil
end

function M.run(arg)
	local cfg = config.load()

	anim.spin("sizing up this machine")

	format.heading("baka status", icons.snowflake)
	print()

	local pkg_count, pkg_label = package_info(cfg)
	local distro_rows = {
		{ "distro", cfg.os_name or cfg.distro or "unknown" },
	}
	if pkg_count then
		table.insert(distro_rows, { "packages", tostring(pkg_count) .. " (" .. pkg_label .. ")" })
	end
	format.heading("distro", icons.package)
	format.kv_list(distro_rows)
	print()

	format.heading("hardware", icons.cpu)
	format.kv_list({
		{ "cpu",    cpu_model() },
		{ "memory", memory_usage() },
		{ "kernel", trimmed("uname -r") },
		{ "uptime", uptime() },
	})
	print()

	local initsys = require("modules.initsys")
	local sys = initsys.status()
	format.heading("services (" .. sys.init_system .. ")", icons.gear)
	if #sys.failed == 0 then
		colors.success(sys.running .. " running, 0 failed -- as it should be")
	else
		colors.error(sys.running .. " running, " .. #sys.failed .. " failed")
		for _, name in ipairs(sys.failed) do
			print("  " .. colors.red .. icons.cross .. colors.reset .. " " .. name)
		end
	end
	print()

	format.heading("vpn", icons.wifi)
	local vpn = require("modules.vpn")
	format.print_vpn(vpn.status())
end

return M
