
local M = {}

local saved_state = nil
function M.is_tty()
	return os.execute("test -t 0 2>/dev/null") == true
		or os.execute("test -t 0 2>/dev/null") == 0
end

local function apply_input_mode()
	os.execute("stty -icanon -echo -isig min 1 time 0 2>/dev/null")
end
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
function M.restore()
	io.write("\27[?25h") -- show cursor
	io.flush()
	if saved_state and saved_state ~= "" then
		os.execute("stty " .. saved_state .. " 2>/dev/null")
	else
		os.execute("stty sane 2>/dev/null")
	end
end
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
