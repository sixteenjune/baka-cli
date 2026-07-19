local M = {}

local colors = require("lib.colors")

local function capture(cmd)
	local handle = io.popen(cmd)

	if not handle then
		return "unknown"
	end

	local output = handle:read("*a")
	handle:close()

	return output:gsub("%s+$", "")
end

local function section(name)
	print()
	print(colors.mauve .. " -> " .. colors.reset .. colors.ice .. name .. ":" .. colors.reset)
end

local function item(name, value)
	print("  " .. colors.blue .. name .. ":" .. colors.reset .. " " .. value)
end

local function service(name)
	local result = os.execute("rc-service " .. name .. " status >/dev/null 2>&1")

	if result == true or result == 0 then
		print("  " .. colors.green .. "✓" .. colors.reset .. " " .. name .. ": running")
	else
		print("  " .. colors.red .. "✗" .. colors.reset .. " " .. name .. ": stopped")
	end
end

function M.run(arg)
	colors.info("checking your system...")

	section("system")

	item("host", capture("hostname"))
	item("kernel", capture("uname -r"))
	item("uptime", capture("uptime -p"))
	item("shell", capture("basename $SHELL"))

	section("hardware")

	item("cpu", capture("lscpu | grep 'Model name' | sed 's/.*: //'"))
	item("gpu", capture("lspci | grep -i 'vga\\|3d' | sed 's/.*: //'"))
	item("memory", capture("free -h | awk '/Mem:/ {print $3 \" / \" $2}'"))

	section("gentoo")

	item("profile", capture("eselect profile show | sed 's/.*: //'"))
	item("compiler", capture("cc --version | head -n1"))
	item("init", "OpenRC")

	section("services")

	service("dbus")
	service("iwd")
	service("netbird")

	print()
	colors.success("system check completed")
end

return M
