local config = require("lib.config")
local colors = require("lib.colors")

local M = {}

local function detect_os()
	local id, name = "unknown", "unknown"
	local f = io.open("/etc/os-release", "r")
	if f then
		for line in f:lines() do
			local k, v = line:match("^([%w_]+)=(.*)$")
			if k == "ID" then
				id = v:gsub('"', "")
			end
			if k == "NAME" then
				name = v:gsub('"', "")
			end
		end
		f:close()
	end
	return id, name
end

local function detect_arch()
	local handle = io.popen("uname -m")
	if not handle then
		return "unknown"
	end
	local arch = handle:read("*l") or "unknown"
	handle:close()
	return arch
end

local function ask(prompt)
	io.write(prompt)
	io.flush()
	return io.read("*l")
end

local function preview_line(p)
	if p.blue == "" then
		return "[baka] -> example step   success  failure"
	end
	return p.blue
		.. "[baka] "
		.. p.reset
		.. p.mauve
		.. "-> "
		.. p.reset
		.. "example step  "
		.. p.green
		.. "success"
		.. p.reset
		.. "  "
		.. p.red
		.. "failure"
		.. p.reset
end

function M.run(arg)
	print(colors.bold .. "baka first-time setup" .. colors.reset)
	print()

	local id, name = detect_os()
	local arch = detect_arch()

	colors.step("detected OS: " .. name .. " (" .. id .. ")")
	colors.step("detected arch: " .. arch)
	print()

	print("choose a color palette:")
	print("  1) none  - plain output, no color")
	print("  2) ice   - classic Cirno, cool and mature blues")
	print("  3) soda  - neon-tinged, bubblier and brighter")
	print()
	print("  " .. preview_line(colors.palettes.none))
	print("  " .. preview_line(colors.palettes.ice))
	print("  " .. preview_line(colors.palettes.soda))
	print()

	local choice
	repeat
		choice = ask("> ")
	until choice == "1" or choice == "2" or choice == "3"

	local palette_map = { ["1"] = "none", ["2"] = "ice", ["3"] = "soda" }
	local palette_name = palette_map[choice]

	config.save({
		os = id,
		os_name = name,
		arch = arch,
		palette = palette_name,
	})

	-- Installs the command line symlink automatically
	print()
	colors.step("installing global symlink...")
	os.execute("mkdir -p ~/.local/bin")

	-- Find the absolute path to this specific baka.lua file
	local path_handle = io.popen("readlink -f '" .. arg[0] .. "'")
	local real_baka_path = path_handle:read("*l")
	path_handle:close()

	local target_bin = os.getenv("HOME") .. "/.local/bin/baka"
	os.execute("ln -sf " .. string.format("%q", real_baka_path) .. " " .. string.format("%q", target_bin))
	colors.success("symlink created at " .. target_bin)

	colors.success("config saved to " .. config.path())
	colors.info("palette set to '" .. palette_name .. "'")
end

return M
