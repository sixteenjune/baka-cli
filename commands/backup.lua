-- commands/backup.lua
-- Creates one timestamped tar.gz per target into ~/backups/, e.g.
--   ~/backups/2026-07-19_hyprland.tar.gz
--
-- Edit `targets` below to add/remove what gets backed up. `privileged`
-- targets are read with doas/sudo and the resulting archive is chowned
-- back to you, so ~/backups/ never ends up with root-owned files in it.

local sudo = require("lib.sudo")
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")

local M = {}

local home = os.getenv("HOME")
local backup_dir = home .. "/backups"

local targets = {
	-- name is the archive's filename prefix; path is what actually gets
	-- tarred. Hyprland's real config dir is ~/.config/hypr, not
	-- ~/.config/hyprland -- keep the friendlier "hyprland" name for the
	-- archive itself.
	{ name = "hyprland", path = home .. "/.config/hypr",    privileged = false },
	{ name = "mako",     path = home .. "/.config/mako",    privileged = false },
	{ name = "waybar",   path = home .. "/.config/waybar",  privileged = false },
	{ name = "kitty",    path = home .. "/.config/kitty",   privileged = false },
	{ name = "matugen",  path = home .. "/.config/matugen", privileged = false },
	{ name = "nvim",     path = home .. "/.config/nvim",    privileged = false },
	{ name = "mpv",      path = home .. "/.config/mpv",     privileged = false },
	{ name = "portage",  path = "/etc/portage",              privileged = true },
	{ name = "dracut",   path = "/etc/dracut.conf.d",        privileged = true },
	{ name = "sysctl",   path = "/etc/sysctl.d",             privileged = true },
	{ name = "confd",    path = "/etc/conf.d",                privileged = true },
}

local function today()
	return os.date("%Y-%m-%d")
end

local function split_path(path)
	local parent = path:match("(.*)/[^/]+$")
	local base = path:match("([^/]+)$")
	return parent, base
end

function M.run(arg)
	os.execute('mkdir -p "' .. backup_dir .. '"')

	anim.spin("packing up your treasures")
	format.heading("backup", icons.package)
	colors.info("backing up into " .. backup_dir)
	print()

	local date = today()
	local uid = exec.capture("id -u"):gsub("%s+$", "")
	local gid = exec.capture("id -g"):gsub("%s+$", "")

	local ok_count, skip_count, fail_count = 0, 0, 0

	for _, t in ipairs(targets) do
		if not exec.path_exists(t.path) then
			colors.warn(t.name .. ": " .. t.path .. " not found, skipping")
			skip_count = skip_count + 1
		else
			local archive = backup_dir .. "/" .. date .. "_" .. t.name .. ".tar.gz"
			local parent, base = split_path(t.path)

			if t.privileged then
				colors.step("archiving " .. t.path .. " (root)")
				local inner = string.format(
					'tar -czf "%s" -C "%s" "%s" && chown %s:%s "%s"',
					archive, parent, base, uid, gid, archive
				)
				local ok = sudo.run("sh -c '" .. inner .. "'", { label = t.name .. " backup" })
				if ok then ok_count = ok_count + 1 else fail_count = fail_count + 1 end
			else
				colors.step("archiving " .. t.path)
				local cmd = string.format('tar -czf "%s" -C "%s" "%s"', archive, parent, base)
				local ok = exec.run_live(cmd)
				if ok then
					colors.success(t.name .. " backed up")
					ok_count = ok_count + 1
				else
					colors.error(t.name .. " backup failed")
					fail_count = fail_count + 1
				end
			end
		end
	end

	print()
	if fail_count == 0 then
		colors.success(ok_count .. " backed up, " .. skip_count .. " skipped -- flawless, as expected")
	else
		colors.warn(ok_count .. " backed up, " .. skip_count .. " skipped, " .. fail_count .. " failed")
		os.exit(1)
	end
end

return M
