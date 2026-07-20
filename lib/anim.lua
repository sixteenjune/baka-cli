-- lib/anim.lua
-- A short, tasteful "loading" flourish -- oscillates . -> .. -> ... -> .. -> .
-- then clears itself. This is flavor, not a real progress bar: Lua's
-- os.execute/io.popen are blocking, so we can't animate *during* a
-- subprocess call without threads. Keep `duration` short so it never
-- feels like it's dragging.

local colors = require("lib.colors")

local M = {}

local FRAMES = { ".", "..", "...", "..", "." }

--- Show the oscillating-dot animation with `message`, then clear the line.
--- @param message string   text before the dots, e.g. "fetching network details"
--- @param duration number|nil  total seconds, default 0.35 (kept short on purpose)
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
