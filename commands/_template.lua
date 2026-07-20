-- commands/_template.lua
-- Copy this to commands/<name>.lua, fill it in, then register it as
-- M.<name> in commands/init.lua (the registry).
--
-- If your command needs the distro/initsys/vpn backends, `require` them
-- INSIDE M.run (not at the top of the file). commands/init.lua eagerly
-- loads every command module, and a top-level require would run the
-- backend's config check (and possibly os.exit) before the user ever
-- picked a command -- see modules/distro/init.lua for why that check
-- exists.

local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")
local sudo = require("lib.sudo")

local M = {}

function M.run(arg)
	-- brief loading flourish for anything that fetches/scans info;
	-- skip it for commands that go straight into a real subprocess
	anim.spin("doing the thing")

	format.heading("section title", icons.gear)
	colors.step("a step worth mentioning")

	-- example: a privileged command (honors the configured doas/sudo
	-- choice, reports real exit codes including ctrl+c as 130)
	-- sudo.run("some-command --flag", { label = "the thing" })

	-- example: a lazily-required backend
	-- local distro = require("modules.distro")
	-- distro.something()

	-- example: pretty table
	-- format.table({ "col1", "col2" }, { { "a", "b" } })

	colors.success("done -- obviously")
end

return M
