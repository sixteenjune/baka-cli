local exec = require("lib.exec")

local M = {}

function M.status()
	if not exec.has("tailscale") then
		return { tool = "tailscale", installed = false }
	end

	local out = exec.capture("tailscale status")
	local connected = out ~= "" and not out:find("[Ss]topped")

	local ip = exec.capture("tailscale ip -4"):gsub("%s+$", "")
	if ip == "" then ip = nil end

	local peer_count = 0
	for _ in out:gmatch("[^\n]+") do
		peer_count = peer_count + 1
	end
	peer_count = math.max(peer_count - 1, 0) -- first line is self

	return {
		tool = "tailscale",
		installed = true,
		connected = connected,
		ip = ip,
		peers = peer_count .. " peer(s)",
	}
end

return M
