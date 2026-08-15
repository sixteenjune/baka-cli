
local colors = require("lib.colors")
local icons = require("lib.icons")
local format = require("lib.format")
local tty = require("lib.tty")

local M = {}

local VIEWPORT = 15

local function state_label(initsys, svc)
	if initsys.is_running(svc.state) then
		return colors.green .. "running" .. colors.reset
	elseif svc.state == "failed" or svc.state == "crashed" then
		return colors.red .. svc.state .. colors.reset
	end
	return colors.grey .. svc.state .. colors.reset
end
local function view_funcs(initsys, secondary)
	if secondary then
		return {
			list = initsys.list_secondary,
			start = initsys.start_secondary or initsys.start,
			stop = initsys.stop_secondary or initsys.stop,
			restart = initsys.restart_secondary or initsys.restart,
			label = initsys.secondary_label or "secondary",
		}
	end
	return {
		list = initsys.list,
		start = initsys.start,
		stop = initsys.stop,
		restart = initsys.restart,
		label = "primary",
	}
end

local function draw(initsys, view_label, services, cursor, scroll, has_secondary)
	io.write("\27[2J\27[H")

	format.heading("services (" .. initsys.name .. ") -- " .. view_label, icons.gear)
	local hint = "up/down move   enter start/stop   r restart   q quit"
	if has_secondary then
		hint = hint .. "   t toggle view"
	end
	print(colors.dim .. hint .. colors.reset)
	print()

	if #services == 0 then
		colors.warn("nothing here")
	end

	local last = math.min(scroll + VIEWPORT, #services)
	for i = scroll + 1, last do
		local svc = services[i]
		local marker = (i == cursor) and (colors.neon .. "> " .. colors.reset) or "  "
		local name = svc.name
		if i == cursor then
			name = colors.bold .. name .. colors.reset
		end
		print(marker .. name .. string.rep(" ", math.max(1, 36 - #svc.name)) .. state_label(initsys, svc))
	end

	print()
	if #services > 0 then
		print(colors.dim .. string.format("%d-%d of %d", scroll + 1, last, #services) .. colors.reset)
	end

	io.flush()
end
local function run_action(svc, action)
	tty.restore()
	print()
	local ok, code = action(svc.name)
	print()
	tty.raw_on()
	colors.step("press any key to continue")
	io.read(1)
	return ok, code
end

function M.run(arg)
	if not tty.is_tty() then
		colors.error("baka services needs an actual terminal -- can't render an arrow-key menu over a pipe")
		os.exit(1)
	end

	local initsys = require("modules.initsys")
	local has_secondary = initsys.list_secondary ~= nil

	local secondary = false
	local funcs = view_funcs(initsys, secondary)
	local services = funcs.list()

	local cursor = 1
	local scroll = 0

	tty.raw_on()

	while true do
		draw(initsys, funcs.label, services, cursor, scroll, has_secondary)

		local key = tty.read_key()

		if key == "up" then
			cursor = math.max(1, cursor - 1)
		elseif key == "down" then
			cursor = math.min(math.max(#services, 1), cursor + 1)
		elseif key == "t" and has_secondary then
			secondary = not secondary
			funcs = view_funcs(initsys, secondary)
			services = funcs.list()
			cursor = 1
			scroll = 0
		elseif key == "enter" and #services > 0 then
			local svc = services[cursor]
			local action = initsys.is_running(svc.state) and funcs.stop or funcs.start
			run_action(svc, action)
			services = funcs.list() -- refresh, state may have changed
		elseif key == "r" and #services > 0 then
			local svc = services[cursor]
			run_action(svc, funcs.restart)
			services = funcs.list()
		elseif key == "q" or key == "esc" or key == "ctrl-c" or key == "eof" then
			break
		end

		if scroll >= cursor then
			scroll = math.max(0, cursor - 1)
		elseif cursor > scroll + VIEWPORT then
			scroll = cursor - VIEWPORT
		end
	end

	tty.restore()
	io.write("\27[2J\27[H")
	io.flush()
	colors.success("out of the menu -- nothing broke, I checked")
end

return M
