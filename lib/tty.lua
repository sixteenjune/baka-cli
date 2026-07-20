-- lib/tty.lua
-- Minimal terminal-mode helpers for arrow-key menus (baka services).
-- No external libraries -- just `stty` shelled out to, which is on every
-- Linux system baka targets.
--
-- Uses `-icanon -echo -isig` rather than the blunter `stty raw`. Full
-- "raw" also disables output post-processing (OPOST/ONLCR), which would
-- corrupt print()'s newlines into a "staircase" any time we print
-- outside the clear-and-redraw cycle (e.g. "press any key to continue"
-- after an action). This mode gives single-keystroke, no-echo input
-- while keeping normal \n -> \r\n handling on output. -isig means
-- Ctrl+C arrives as a plain byte (3) for us to handle in read_key(),
-- rather than killing the process before restore() can run.

local M = {}

local saved_state = nil

--- True if stdin is an actual terminal. Interactive menus need this --
--- piped/non-tty input would otherwise hang forever on the first read.
function M.is_tty()
	return os.execute("test -t 0 2>/dev/null") == true
		or os.execute("test -t 0 2>/dev/null") == 0
end

local function apply_input_mode()
	os.execute("stty -icanon -echo -isig min 1 time 0 2>/dev/null")
end

--- Enter single-keystroke, no-echo input mode, remembering the previous
--- settings so M.restore() can put the terminal back exactly as it was.
function M.raw_on()
	local handle = io.popen("stty -g 2>/dev/null")
	if handle then
		saved_state = handle:read("*l")
		handle:close()
	end
	apply_input_mode()
	io.write("\27[?25l") -- hide cursor
	io.flush()
end

--- Restore whatever terminal mode was active before raw_on(). Always
--- call this before returning/erroring out of an interactive command,
--- and before anything that needs normal line input (doas/sudo password
--- prompts) -- leaving a user's shell in single-keystroke mode is nasty.
function M.restore()
	io.write("\27[?25h") -- show cursor
	io.flush()
	if saved_state and saved_state ~= "" then
		os.execute("stty " .. saved_state .. " 2>/dev/null")
	else
		os.execute("stty sane 2>/dev/null")
	end
end

--- Read one keypress and decode it. Returns one of:
--- "up" "down" "left" "right" "enter" "esc" "q" "r" "ctrl-c" "eof"
--- or a single raw character for anything else.
---
--- Bare Esc (no follow-up bytes) resolves to "esc" quickly rather than
--- hanging forever waiting for a `[` that isn't coming -- we briefly
--- switch to a non-blocking peek (VMIN=0 VTIME=1, ~0.1s) just for that.
function M.read_key()
	local c = io.read(1)
	if not c then
		return "eof"
	end

	local b = string.byte(c)

	if b == 27 then
		os.execute("stty min 0 time 1 2>/dev/null")
		local c2 = io.read(1)
		if c2 == "[" then
			local c3 = io.read(1)
			apply_input_mode()
			if c3 == "A" then return "up" end
			if c3 == "B" then return "down" end
			if c3 == "C" then return "right" end
			if c3 == "D" then return "left" end
			return "esc"
		end
		apply_input_mode()
		return "esc"
	elseif b == 13 or b == 10 then
		return "enter"
	elseif b == 3 then
		return "ctrl-c"
	elseif c == "q" or c == "Q" then
		return "q"
	elseif c == "r" or c == "R" then
		return "r"
	end

	return c
end

--- Wait up to `deciseconds` (tenths of a second) for a keypress, without
--- blocking indefinitely if none comes. Used by live-updating views
--- (baka cpu) so the same call doubles as both the tick interval and a
--- responsive quit-key check -- no separate sleep() needed.
--- Returns "" on timeout, or a decoded key ("q", "esc", "ctrl-c", or the
--- raw character) if one arrived.
function M.wait_key(deciseconds)
	os.execute("stty -icanon -echo -isig min 0 time " .. deciseconds .. " 2>/dev/null")
	local c = io.read(1)
	apply_input_mode()

	if not c or c == "" then
		return ""
	end
	if c == "q" or c == "Q" then
		return "q"
	end

	local b = string.byte(c)
	if b == 27 then
		return "esc"
	elseif b == 3 then
		return "ctrl-c"
	end

	return c
end

return M
