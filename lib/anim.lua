
local colors = require("lib.colors")

local M = {}

local FRAMES = { ".", "..", "...", "..", "." }
function M.spin(message, duration)
	duration = duration or 0.35
	local frame_time = duration / #FRAMES

	for _, dots in ipairs(FRAMES) do
		io.write("\r" .. colors.blue .. "[baka] " .. colors.reset .. message .. dots .. string.rep(" ", 4))
		io.flush()
		os.execute("sleep " .. frame_time)
	end

	io.write("\r" .. string.rep(" ", #message + 20) .. "\r")
	io.flush()
end

return M
