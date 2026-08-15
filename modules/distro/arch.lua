local sudo = require("lib.sudo")
local exec = require("lib.exec")
local colors = require("lib.colors")
local config = require("lib.config")

local M = {}

local function aur_helper()
	local cfg = config.load()
	return cfg.aur_helper ~= "" and cfg.aur_helper or "paru"
end
function M.rebuild()
	local helper = aur_helper()
	return sudo.run(helper .. " -S --noconfirm $(pacman -Qqn)", { label = "rebuild (full reinstall)" })
end

function M.update()
	local helper = aur_helper()
	return sudo.run(helper .. " -Syu", { label = "update" })
end

function M.clean()
	local helper = aur_helper()
	local ok1, c1 = sudo.run(helper .. " -Sc", { label = "package cache clean" })

	local orphans = exec.capture("pacman -Qtdq"):gsub("%s+$", "")
	if orphans == "" then
		colors.info("no orphaned packages to remove")
		if not ok1 then return false, c1 end
		return true, 0
	end

	local pkglist = orphans:gsub("\n", " ")
	local ok2, c2 = sudo.run("pacman -Rns " .. pkglist, { label = "orphan removal" })

	if not ok1 then return false, c1 end
	if not ok2 then return false, c2 end
	return true, 0
end
function M.why(pkg)
	if not pkg then
		colors.error("usage: baka why <package>")
		os.exit(1)
	end
	if not exec.has("pactree") then
		colors.error("pactree not found -- install pacman-contrib")
		os.exit(1)
	end
	local ok, code = exec.run_live("pactree -r " .. pkg)
	if not ok then os.exit(code) end
end
function M.files(pkg)
	if not pkg then
		colors.error("usage: baka files <package>")
		os.exit(1)
	end
	local ok, code = exec.run_live("pacman -Ql " .. pkg)
	if not ok then os.exit(code) end
end

function M.package_count()
	local out = exec.capture("pacman -Qq 2>/dev/null | wc -l")
	return tonumber(out:match("%d+")) or 0
end

return M
