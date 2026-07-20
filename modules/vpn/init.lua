-- modules/vpn/init.lua
local config = require("lib.config")

local cfg = config.load()

if cfg.vpn == "tailscale" then
	return require("modules.vpn.tailscale")
elseif cfg.vpn == "netbird" then
	return require("modules.vpn.netbird")
else
	return require("modules.vpn.none")
end
