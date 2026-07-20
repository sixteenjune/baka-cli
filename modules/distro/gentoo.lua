-- modules/distro/gentoo.lua
local sudo = require("lib.sudo")
local exec = require("lib.exec")
local colors = require("lib.colors")

local M = {}

--- All of these return (ok, code) so the calling command can propagate a
--- real process exit code -- printing "exit code: 130" is only half the
--- point if `echo $?` after `baka update` still says 0.

function M.rebuild()
	return sudo.run("emerge -e --keep-going --with-bdeps=y --ask @world", { label = "rebuild" })
end

function M.update()
	sudo.run_or_exit("emerge --sync", { label = "sync" })
	-- run_or_exit already ends the process if sync failed/was interrupted;
	-- reaching here means it succeeded
	return sudo.run("emerge -uDNa @world", { label = "update" })
end

function M.clean()
	local ok1, c1 = sudo.run("eclean-dist --deep", { label = "eclean-dist" })
	local ok2, c2 = sudo.run("eclean-pkg --deep", { label = "eclean-pkg" })
	local ok3, c3 = sudo.run("emerge --depclean --ask", { label = "depclean" })

	if not ok1 then return false, c1 end
	if not ok2 then return false, c2 end
	if not ok3 then return false, c3 end
	return true, 0
end

function M.why(pkg)
	if not pkg then
		colors.error("usage: baka why <package>")
		os.exit(1)
	end
	local ok, code = exec.run_live("equery depends " .. pkg)
	if not ok then os.exit(code) end
end

function M.files(pkg)
	if not pkg then
		colors.error("usage: baka files <package>")
		os.exit(1)
	end
	local ok, code = exec.run_live("equery files " .. pkg)
	if not ok then os.exit(code) end
end

--- Installed package count. Counts /var/db/pkg/*/* directories directly
--- rather than shelling out to qlist/equery, so it works even without
--- app-portage/portage-utils installed.
function M.package_count()
	local out = exec.capture("find /var/db/pkg -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l")
	return tonumber(out:match("%d+")) or 0
end

return M
