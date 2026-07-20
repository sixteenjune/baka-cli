-- lib/format.lua
-- Shared pretty-printing helpers used by storage/ports/network/status.

local colors = require("lib.colors")

local M = {}

--- Format a byte count as a human-readable string, e.g. 1536 -> "1.5K".
function M.human_bytes(bytes)
	bytes = tonumber(bytes) or 0
	local units = { "B", "K", "M", "G", "T", "P" }
	local i = 1
	while bytes >= 1024 and i < #units do
		bytes = bytes / 1024
		i = i + 1
	end
	if i == 1 then
		return string.format("%d%s", bytes, units[i])
	end
	return string.format("%.1f%s", bytes, units[i])
end

--- Strip ANSI escape codes, for measuring visible width.
local function plain_len(s)
	local stripped = tostring(s):gsub("\27%[[%d;]*m", "")
	return #stripped
end

--- A single-color progress bar for a 0-100 percent value.
--- Colors itself red/yellow/blue based on how full it is.
function M.bar(percent, width)
	width = width or 24
	percent = math.max(0, math.min(100, percent))
	local filled = math.floor(width * percent / 100 + 0.5)
	local empty = width - filled

	local color = colors.blue
	if percent >= 90 then
		color = colors.red
	elseif percent >= 70 then
		color = colors.yellow
	end

	return color .. string.rep("#", filled) .. colors.reset ..
		colors.grey .. string.rep("-", empty) .. colors.reset
end

--- A multi-segment bar. segments = { {pct=.., color=..}, ... }
--- Segment percentages should sum to <= 100.
function M.segment_bar(segments, width)
	width = width or 40
	local bar = ""
	local used = 0
	for _, seg in ipairs(segments) do
		local w = math.floor(width * seg.pct / 100 + 0.5)
		used = used + w
		bar = bar .. seg.color .. string.rep("#", w) .. colors.reset
	end
	if used < width then
		bar = bar .. colors.grey .. string.rep("-", width - used) .. colors.reset
	end
	return bar
end

--- Print an aligned table. headers = {"a","b"}, rows = {{"1","2"}, ...}
--- Cells may already contain ANSI color codes.
function M.table(headers, rows)
	local widths = {}
	for i, h in ipairs(headers) do
		widths[i] = plain_len(h)
	end
	for _, row in ipairs(rows) do
		for i, cell in ipairs(row) do
			widths[i] = math.max(widths[i] or 0, plain_len(cell))
		end
	end

	local function pad(cell, width)
		local padding = width - plain_len(cell)
		if padding < 0 then padding = 0 end
		return tostring(cell) .. string.rep(" ", padding)
	end

	local header_line = {}
	for i, h in ipairs(headers) do
		table.insert(header_line, pad(colors.bold .. h .. colors.reset, widths[i]))
	end
	print(table.concat(header_line, "  "))

	local rule = {}
	for i in ipairs(headers) do
		table.insert(rule, string.rep("-", widths[i]))
	end
	print(colors.grey .. table.concat(rule, "  ") .. colors.reset)

	for _, row in ipairs(rows) do
		local line = {}
		for i, cell in ipairs(row) do
			table.insert(line, pad(cell, widths[i]))
		end
		print(table.concat(line, "  "))
	end
end

--- Print a section heading. Bright/neon, consistent with the
--- root-privilege banner in lib/sudo.lua. `icon` is optional and should
--- be used sparingly -- one glyph per heading, not per line.
function M.heading(text, icon)
	local prefix = icon and (icon .. "  ") or ""
	print(colors.neon .. colors.bold .. prefix .. text .. colors.reset)
end

--- Print a list of {label, value} pairs with labels aligned to the
--- widest label in the list. Used for status/hardware/disk breakdowns
--- where consistent column alignment matters.
--- @param rows table  list of {label, value}
--- @param opts table|nil  { indent = "  ", label_color = colors.blue }
function M.kv_list(rows, opts)
	opts = opts or {}
	local indent = opts.indent or "  "
	local label_color = opts.label_color or colors.blue

	local width = 0
	for _, row in ipairs(rows) do
		if plain_len(row[1]) > width then
			width = plain_len(row[1])
		end
	end

	for _, row in ipairs(rows) do
		local label, value = row[1], row[2]
		local padding = width - plain_len(label)
		if padding < 0 then padding = 0 end
		print(indent .. label_color .. label .. colors.reset ..
			string.rep(" ", padding) .. "  " .. value)
	end
end

--- Print rows with per-column alignment, no header/rule -- for compact
--- numeric summaries (storage breakdown, swap) where a full table() with
--- header+rule would feel heavier than needed. Uses the same width/pad
--- logic as M.table so spacing behavior stays identical across the app.
--- @param rows table  list of row tables, cells may include ANSI color
--- @param aligns table|nil  list of "left"/"right" per column, default "left"
function M.aligned_rows(rows, aligns)
	aligns = aligns or {}
	local widths = {}
	for _, row in ipairs(rows) do
		for i, cell in ipairs(row) do
			widths[i] = math.max(widths[i] or 0, plain_len(cell))
		end
	end

	local function pad(cell, width, align)
		local padding = width - plain_len(cell)
		if padding < 0 then padding = 0 end
		if align == "right" then
			return string.rep(" ", padding) .. tostring(cell)
		end
		return tostring(cell) .. string.rep(" ", padding)
	end

	for _, row in ipairs(rows) do
		local line = {}
		for i, cell in ipairs(row) do
			table.insert(line, pad(cell, widths[i], aligns[i] or "left"))
		end
		print("  " .. table.concat(line, "  "))
	end
end

--- Shared printer for the {tool, installed, connected, ip, peers} shape
--- returned by modules/vpn/*.lua, so status/network render it identically.
function M.print_vpn(status)
	if status.tool == "none" then
		colors.warn("no VPN configured -- see `baka init`")
		return
	end
	if not status.installed then
		colors.warn(status.tool .. " is configured but not installed")
		return
	end
	if status.connected then
		local suffix = status.ip and (" -- " .. status.ip) or ""
		colors.success(status.tool .. " connected" .. suffix)
	else
		colors.error(status.tool .. " not connected")
	end
	if status.peers then
		colors.step("peers: " .. status.peers)
	end
end

return M
