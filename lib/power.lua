
local exec = require("lib.exec")

local M = {}
function M.detect_tool()
	if exec.has("tlp-stat") then
		local out = exec.capture("tlp-stat -s 2>/dev/null")
		local state = out:match("State%s*=%s*(%a+)")
		if state then
			return "tlp (" .. state:lower() .. ")"
		end
		return "tlp (installed)"
	end
	if exec.has("auto-cpufreq") then
		return "auto-cpufreq (installed)"
	end
	return "none"
end

function M.governor()
	local out = exec.capture("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null"):gsub("%s+$", "")
	return out ~= "" and out or "unknown"
end
function M.turbo_status()
	local no_turbo = exec.capture("cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null"):gsub("%s+$", "")
	if no_turbo ~= "" then
		return no_turbo == "0" and "enabled" or "disabled"
	end

	local boost = exec.capture("cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null"):gsub("%s+$", "")
	if boost ~= "" then
		return boost == "1" and "enabled" or "disabled"
	end

	return "unknown"
end
function M.zones()
	local out = exec.capture("ls -d /sys/class/thermal/thermal_zone* 2>/dev/null")
	local list = {}
	for path in out:gmatch("[^\n]+") do
		local label = exec.capture("cat " .. path .. "/type 2>/dev/null"):gsub("%s+$", "")
		local raw = exec.capture("cat " .. path .. "/temp 2>/dev/null"):gsub("%s+$", "")
		local milli = tonumber(raw)
		if milli then
			table.insert(list, { label = label ~= "" and label or path, celsius = milli / 1000 })
		end
	end
	return list
end
function M.primary_temp()
	local zones = M.zones()
	if #zones == 0 then
		return nil
	end

	for _, z in ipairs(zones) do
		local label = z.label:lower()
		if label:find("pkg") or label:find("cpu") or label:find("core") then
			return z.celsius
		end
	end

	local sum = 0
	for _, z in ipairs(zones) do
		sum = sum + z.celsius
	end
	return sum / #zones
end

return M
