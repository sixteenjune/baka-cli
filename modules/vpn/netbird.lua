-- modules/vpn/netbird.lua
local exec = require("lib.exec")

local M = {}

function M.status()
	if not exec.has("netbird") then
		return { tool = "netbird", installed = false }
	end

	local out = exec.capture("netbird status")
	local connected = out:find("Management: Connected") ~= nil
	local ip = out:match("NetBird IP:%s*(%S+)")
	local peers = out:match("Peers count:%s*([%d/]+%s*%a*)")

	return {
		tool = "netbird",
		installed = true,
		connected = connected,
		ip = ip,
		peers = peers,
	}
end

return M
