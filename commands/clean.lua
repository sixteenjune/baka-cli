-- commands/clean.lua
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")

local M = {}

--- Offer to remove stale /lib/modules/* dirs (distro-agnostic, so it
--- lives here rather than in modules/distro/*) -- see the doc comment
--- on modules/kernel.lua's find_stale_modules for why this is needed.
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

function M.run(arg)
	local distro = require("modules.distro")
	local ok, code = distro.clean()

	clean_old_kernels()

	if not ok then
		os.exit(code)
	end
end

return M
