
local config = require("lib.config")

local cfg = config.load()

if cfg.init_system == "openrc" then
	return require("modules.initsys.openrc")
else
	return require("modules.initsys.systemd")
end
