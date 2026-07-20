-- modules/initsys/init.lua
-- Picks the systemd or openrc backend based on config. This only backs
-- read-only status reporting, so unlike modules/distro it soft-defaults
-- to systemd rather than hard-failing when unconfigured.

local config = require("lib.config")

local cfg = config.load()

if cfg.init_system == "openrc" then
	return require("modules.initsys.openrc")
else
	return require("modules.initsys.systemd")
end
