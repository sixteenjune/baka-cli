
local colors = require("lib.colors")

local M = {}
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
local function plain_len(s)
	local stripped = tostring(s):gsub("\27%[[%d;]*m", "")
	return #stripped
end
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
function M.heading(text, icon)
	local prefix = icon and (icon .. "  ") or ""
	print(colors.neon .. colors.bold .. prefix .. text .. colors.reset)
end
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
function M.temp_colored(celsius, text)
	text = text or string.format("%.1fC", celsius)
	if celsius >= 85 then return colors.red .. text .. colors.reset end
	if celsius >= 70 then return colors.yellow .. text .. colors.reset end
	return colors.green .. text .. colors.reset
end
function M.pct_colored(percent, text)
	text = text or string.format("%.1f%%", percent)
	if percent >= 90 then return colors.red .. text .. colors.reset end
	if percent >= 70 then return colors.yellow .. text .. colors.reset end
	return colors.blue .. text .. colors.reset
end

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
function M.speed_colored(mbps, text)
	text = text or string.format("%.1f Mbps", mbps)
	if mbps < 10 then return colors.red .. text .. colors.reset end
	if mbps < 50 then return colors.yellow .. text .. colors.reset end
	return colors.green .. text .. colors.reset
end

return M
