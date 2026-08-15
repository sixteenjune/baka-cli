
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")

local M = {}

local home = os.getenv("HOME")

local function bytes_of(path)
	local out = exec.capture(string.format('timeout 20 du -sb "%s"', path))
	local n = out:match("^(%d+)")
	return tonumber(n) or 0
end

local function root_usage()
	local out = exec.capture("df -B1 --output=size,used / | tail -n1")
	local size, used = out:match("(%d+)%s+(%d+)")
	return tonumber(size) or 0, tonumber(used) or 0
end

local function swap_usage()
	local out = exec.capture("free -b")
	for line in out:gmatch("[^\n]+") do
		local total, used = line:match("^Swap:%s+(%d+)%s+(%d+)")
		if total then
			return tonumber(total), tonumber(used)
		end
	end
	return 0, 0
end

function M.run(arg)
	anim.spin("scanning your ice-cold disks")

	local root_size, root_used = root_usage()
	local tmp_bytes = bytes_of("/tmp")
	local home_bytes = bytes_of(home)

	local other_bytes = root_used - tmp_bytes - home_bytes
	if other_bytes < 0 then
		other_bytes = 0
	end

	local function pct(n)
		return root_used > 0 and (n / root_used * 100) or 0
	end

	local segments = {
		{ label = "~ (" .. home .. ")", bytes = home_bytes,  pct = pct(home_bytes),  color = colors.blue },
		{ label = "/tmp",               bytes = tmp_bytes,   pct = pct(tmp_bytes),   color = colors.mauve },
		{ label = "other",              bytes = other_bytes, pct = pct(other_bytes), color = colors.grey },
	}

	format.heading("disk usage breakdown", icons.disk)
	colors.step("of " .. format.human_bytes(root_used) .. " used on /")
	print()
	print("  " .. format.segment_bar(segments, 40))
	print()

	local rows = {}
	for _, seg in ipairs(segments) do
		table.insert(rows, {
			seg.color .. seg.label .. colors.reset,
			string.format("%.1f%%", seg.pct),
			format.human_bytes(seg.bytes),
		})
	end
	format.aligned_rows(rows, { "left", "right", "right" })

	print()
	local disk_pct = root_size > 0 and (root_used / root_size * 100) or 0
	format.aligned_rows({
		{ "disk fill", format.bar(disk_pct, 20), string.format("%.1f%%", disk_pct),
			format.human_bytes(root_used) .. " / " .. format.human_bytes(root_size) },
	}, { "left", "left", "right", "right" })

	print()
	format.heading("swap", icons.bolt)
	local swap_total, swap_used = swap_usage()
	if swap_total == 0 then
		colors.warn("no swap configured -- living dangerously")
	else
		local swap_pct = swap_used / swap_total * 100
		format.aligned_rows({
			{ "", format.bar(swap_pct, 20), string.format("%.1f%%", swap_pct),
				format.human_bytes(swap_used) .. " / " .. format.human_bytes(swap_total) },
		}, { "left", "left", "right", "right" })
	end

	print()
	format.heading("largest items in " .. home, icons.package)
	local du_out = exec.capture(string.format(
		'find "%s" -mindepth 1 -maxdepth 1 -print0 | xargs -0 du -sb 2>/dev/null | sort -rn | head -5',
		home
	))
	local top_rows = {}
	for line in du_out:gmatch("[^\n]+") do
		local size, path = line:match("^(%d+)%s+(.+)$")
		if size then
			table.insert(top_rows, { format.human_bytes(tonumber(size)), path })
		end
	end
	if #top_rows > 0 then
		format.table({ "size", "path" }, top_rows)
	end
end

return M
