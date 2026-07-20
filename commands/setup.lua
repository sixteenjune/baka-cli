-- commands/setup.lua
-- Implements `baka init`. Registered as M.init in commands/init.lua.
--
-- Named setup.lua (not initialize.lua) on purpose -- commands/init.lua is
-- the *command registry* (Lua's dir+init.lua package convention), not
-- this command. Two files both called "init" was asking for confusion.
--
-- Idempotent: safe to re-run any time you want to tweak one setting.
-- Every question shows your current value as the default (just press
-- enter to keep it) instead of forcing you to re-answer everything.

local config = require("lib.config")
local colors = require("lib.colors")
local icons = require("lib.icons")
local exec = require("lib.exec")

local M = {}

local function detect_os()
	local id, name = "unknown", "unknown"
	local f = io.open("/etc/os-release", "r")
	if f then
		for line in f:lines() do
			local k, v = line:match("^([%w_]+)=(.*)$")
			if k == "ID" then id = v:gsub('"', "") end
			if k == "NAME" then name = v:gsub('"', "") end
		end
		f:close()
	end
	return id, name
end

local function detect_arch()
	local out = exec.capture("uname -m"):gsub("%s+$", "")
	return out ~= "" and out or "unknown"
end

--- Numbered-choice prompt. If `current` matches a choice's value, it's
--- marked and pressing enter with no input keeps it -- this is what
--- makes re-running `baka init` idempotent instead of a full reset.
local function ask_choice(prompt, choices, current)
	print(prompt)
	for i, c in ipairs(choices) do
		local marker = ""
		if c.value == current then
			marker = colors.grey .. "  (current)" .. colors.reset
		end
		print(string.format("  %d) %s%s", i, c.label, marker))
	end
	print()

	while true do
		if current then
			io.write("> [enter to keep current] ")
		else
			io.write("> ")
		end
		io.flush()
		local answer = io.read("*l")

		if current and (not answer or answer == "") then
			print()
			return current
		end

		local choice = choices[tonumber(answer or "")]
		if choice then
			print()
			return choice.value
		end

		colors.warn("that's not one of the options -- try again, baka")
	end
end

local function palette_preview(p)
	if p.blue == "" then
		return "[baka] -> example step  success  failure"
	end
	return p.blue .. "[baka] " .. p.reset ..
		p.mauve .. "-> " .. p.reset .. "example step  " ..
		p.green .. "success" .. p.reset .. "  " ..
		p.red .. "failure" .. p.reset
end

--- Idempotently install ~/.local/bin/baka as a symlink to this script.
--- Only touches disk if the symlink is missing or pointing elsewhere.
local function ensure_symlink(arg0)
	local bin_dir = os.getenv("HOME") .. "/.local/bin"
	local target_bin = bin_dir .. "/baka"

	local path_handle = io.popen("readlink -f '" .. arg0 .. "'")
	local real_baka_path = path_handle:read("*l")
	path_handle:close()

	local current_target = exec.capture("readlink -f '" .. target_bin .. "'"):gsub("%s+$", "")

	if current_target == real_baka_path then
		colors.step("symlink already points at me -- nothing to do")
		return
	end

	os.execute('mkdir -p "' .. bin_dir .. '"')
	os.execute("ln -sf " .. string.format("%q", real_baka_path) .. " " .. string.format("%q", target_bin))
	colors.success(icons.link .. " symlink installed at " .. target_bin)

	local path_env = os.getenv("PATH") or ""
	if not path_env:find(bin_dir, 1, true) then
		colors.warn(bin_dir .. " isn't on your PATH yet -- add it or `baka` won't resolve globally")
	end
end

function M.run(arg)
	local existing = config.load()
	local first_run = not config.exists()

	print(colors.neon .. colors.bold .. icons.snowflake .. "  the STRONGEST setup wizard has arrived" .. colors.reset)
	if first_run then
		print(colors.dim .. "(never run before -- let's get you set up, obviously)" .. colors.reset)
	else
		print(colors.dim .. "(re-running -- press enter on anything you don't want to change)" .. colors.reset)
	end
	print()

	local id, name = detect_os()
	local arch = detect_arch()
	colors.step("detected: " .. name .. " (" .. id .. "), " .. arch)
	print()

	local distro = ask_choice("which package manager bows to you?", {
		{ label = "gentoo (portage)",    value = "gentoo" },
		{ label = "arch linux (pacman)", value = "arch" },
	}, existing.distro)

	local aur_helper = existing.aur_helper or ""
	if distro == "arch" then
		aur_helper = ask_choice("which AUR helper do you use?", {
			{ label = "yay",  value = "yay" },
			{ label = "paru", value = "paru" },
		}, existing.aur_helper)
	end

	local init_system = ask_choice("which init system does this machine use?", {
		{ label = "systemd", value = "systemd" },
		{ label = "openrc",  value = "openrc" },
	}, existing.init_system)

	local vpn = ask_choice("which VPN mesh do you use, if any?", {
		{ label = "netbird",   value = "netbird" },
		{ label = "tailscale", value = "tailscale" },
		{ label = "none",      value = "none" },
	}, existing.vpn)

	local escalation = ask_choice("doas or sudo? (I don't judge... much)", {
		{ label = "doas", value = "doas" },
		{ label = "sudo", value = "sudo" },
	}, existing.escalation)

	print("choose a color palette:")
	print()
	print("  1) none  - plain output, no color")
	print("  " .. palette_preview(colors.palettes.none))
	print()
	print("  2) ice   - classic Cirno, cool and mature blues")
	print("  " .. palette_preview(colors.palettes.ice))
	print()
	print("  3) soda  - neon-tinged, bubblier and brighter")
	print("  " .. palette_preview(colors.palettes.soda))
	print()

	local palette = ask_choice("pick a palette", {
		{ label = "none", value = "none" },
		{ label = "ice",  value = "ice" },
		{ label = "soda", value = "soda" },
	}, existing.palette)

	config.save({
		os          = id,
		os_name     = name,
		arch        = arch,
		distro      = distro,
		aur_helper  = aur_helper,
		init_system = init_system,
		vpn         = vpn,
		escalation  = escalation,
		palette     = palette,
	})

	colors.step("installing global symlink...")
	ensure_symlink(arg[0])

	print()
	colors.success("config saved to " .. config.path())
	colors.success("setup complete -- I'm the STRONGEST cli now, hyahaha~")
end

return M
