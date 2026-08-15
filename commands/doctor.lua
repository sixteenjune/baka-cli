
local config = require("lib.config")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local exec = require("lib.exec")
local anim = require("lib.anim")

local M = {}

local pass_count, fail_count, warn_count = 0, 0, 0

local function check(ok, label, detail)
	if ok then
		print("  " .. colors.green .. icons.check .. colors.reset .. " " .. label)
		pass_count = pass_count + 1
	else
		print(
			"  " .. colors.red .. icons.cross .. colors.reset .. " " .. label .. (detail and (" -- " .. detail) or "")
		)
		fail_count = fail_count + 1
	end
end

local function warn(label, detail)
	print("  " .. colors.yellow .. icons.warn .. colors.reset .. " " .. label .. (detail and (" -- " .. detail) or ""))
	warn_count = warn_count + 1
end

function M.run(arg)
	anim.spin("giving myself a check-up")
	format.heading("doctor", icons.snowflake)
	print()

	local has_config = config.exists()
	local cfg = config.load()

	format.heading("config", icons.gear)
	check(has_config, "config file exists (" .. config.path() .. ")")
	if has_config then
		local complete = true
		for _, field in ipairs({ "distro", "init_system", "escalation", "palette" }) do
			if not cfg[field] or cfg[field] == "" then
				complete = false
			end
		end
		check(complete, "all core settings present", not complete and "run `baka init` to fill in the gaps" or nil)
	else
		warn("no config yet", "run `baka init` first")
	end
	print()

	format.heading("symlink", icons.link)
	local home = os.getenv("HOME") or ""
	local bin_dir = home .. "/.local/bin"
	local target = bin_dir .. "/baka"
	check(exec.path_exists(target), target .. " exists")
	local path_env = os.getenv("PATH") or ""
	if path_env:find(bin_dir, 1, true) then
		check(true, bin_dir .. " is on PATH")
	else
		warn(bin_dir .. " is not on PATH", "baka won't resolve globally")
	end
	print()

	if has_config then
		format.heading("privilege escalation", icons.lock)
		local tool = cfg.escalation == "sudo" and "sudo" or "doas"
		check(exec.has(tool), tool .. " is installed")
		print()

		if cfg.distro == "gentoo" then
			format.heading("distro: gentoo", icons.package)
			for _, bin in ipairs({ "emerge", "equery", "eclean-dist", "eclean-pkg" }) do
				check(exec.has(bin), bin .. " is installed")
			end
			print()
		elseif cfg.distro == "arch" then
			format.heading("distro: arch", icons.package)
			local helper = cfg.aur_helper ~= "" and cfg.aur_helper or "paru"
			check(exec.has(helper), helper .. " (AUR helper) is installed")
			if exec.has("pactree") then
				check(true, "pactree is installed")
			else
				warn("pactree is not installed", "baka why needs pacman-contrib")
			end
			print()
		end

		if cfg.vpn and cfg.vpn ~= "none" then
			format.heading("vpn: " .. cfg.vpn, icons.wifi)
			check(exec.has(cfg.vpn), cfg.vpn .. " is installed")
			print()
		end

		format.heading("kernel building", icons.bolt)
		if exec.path_exists("/usr/src/linux") then
			check(true, "/usr/src/linux exists")
		else
			warn("/usr/src/linux not found", "baka kernel won't work until it does")
		end
		check(exec.has("dracut"), "dracut is installed")
		if cfg.bootloader == "grub" then
			check(exec.has("grub-mkconfig"), "grub-mkconfig is installed")
		elseif cfg.bootloader == "limine" then
			print("  " .. colors.green .. icons.check .. colors.reset .. " limine configured")
			pass_count = pass_count + 1
		end
		print()
	end

	if fail_count == 0 and warn_count == 0 then
		colors.success(pass_count .. " checks passed -- flawless, obviously")
	elseif fail_count == 0 then
		colors.warn(pass_count .. " passed, " .. warn_count .. " warning(s) -- nothing urgent")
	else
		colors.error(pass_count .. " passed, " .. warn_count .. " warning(s), " .. fail_count .. " failed")
		os.exit(1)
	end
end

return M
