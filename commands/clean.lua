local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local sudo = require("lib.sudo")
local exec = require("lib.exec")

local M = {}
local function clean_old_kernels()
	local kernel = require("modules.kernel")
	local stale, running = kernel.find_stale_modules()

	if #stale == 0 then
		return
	end

	print()
	format.heading("old kernel modules", icons.bolt)
	colors.step("currently running: " .. running)
	colors.warn(#stale .. " other version(s) found: " .. table.concat(stale, ", "))
	io.write("remove them? [y/N] ")
	io.flush()
	local answer = io.read("*l")

	if answer and answer:lower() == "y" then
		for _, version in ipairs(stale) do
			kernel.remove_modules(version)
		end
	else
		colors.info("leaving them alone")
	end
end
local function trim_ssd()
	if not exec.has("fstrim") then
		colors.info("fstrim not found, skipping SSD trim")
		return
	end

	print()
	format.heading("ssd trim", icons.disk)
	local ok, code = sudo.run("fstrim -av", { label = "fstrim" })
	if not ok and code ~= 130 then
		colors.warn("fstrim failed (exit code " .. code .. "), continuing anyway")
	end
end

function M.run(arg)
	local distro = require("modules.distro")
	local ok, code = distro.clean()

	trim_ssd()
	clean_old_kernels()

	if not ok then
		os.exit(code)
	end
end

return M
