-- commands/ports.lua
local exec = require("lib.exec")
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local anim = require("lib.anim")
local config = require("lib.config")

local M = {}

-- parses the `Process` column, e.g. users:(("sshd",pid=1234,fd=3))
local function parse_process(field)
	local name, pid = field:match('%(%"([^"]+)%",pid=(%d+)')
	if name then
		return name, pid
	end
	return "-", "-"
end

function M.run(arg)
	if not exec.has("ss") then
		colors.error("'ss' not found -- install iproute2")
		os.exit(1)
	end

	local cfg = config.load()
	local tool = cfg.escalation == "sudo" and "sudo" or "doas"

	anim.spin("scanning for open doors")
	colors.neon_tag(icons.lock .. " requesting root privileges (" .. tool .. ") for process details")

	local output = exec.capture(tool .. " ss -tulnp")
	if output == "" then
		colors.error("could not read socket info")
		os.exit(1)
	end

	local rows = {}
	local first = true
	for line in output:gmatch("[^\n]+") do
		if first then
			first = false
		else
			local tokens = {}
			for tok in line:gmatch("%S+") do
				table.insert(tokens, tok)
			end

			local proto, local_addr = tokens[1], tokens[5]
			local process_field = table.concat(tokens, " ", 7)
			local name, pid = parse_process(process_field or "")

			-- distinct hues per protocol, not just a stylistic pick from
			-- adjacent blues -- tcp/udp should be tell-apart-at-a-glance
			local proto_colored
			if proto == "tcp" then
				proto_colored = colors.blue .. proto .. colors.reset
			elseif proto == "udp" then
				proto_colored = colors.yellow .. proto .. colors.reset
			else
				proto_colored = colors.grey .. (proto or "-") .. colors.reset
			end

			table.insert(rows, { proto_colored, local_addr or "-", name, pid })
		end
	end

	print()
	format.heading("open ports", icons.wifi)

	if #rows == 0 then
		colors.warn("nothing listening -- suspiciously quiet")
		return
	end

	format.table({ "proto", "local address", "process", "pid" }, rows)
end

return M
