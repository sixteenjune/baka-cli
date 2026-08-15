local sudo = require("lib.sudo")
local exec = require("lib.exec")
local colors = require("lib.colors")
local config = require("lib.config")

local M = {}

local KERNEL_DIR = "/usr/src/linux"

local function compiler_args()
	local cfg = config.load()
	if cfg.compiler ~= "llvm" then
		return "", ""
	end

	local llvm_bin = exec.capture("ls -d /usr/lib/llvm/*/bin 2>/dev/null | sort -V | tail -n1"):gsub("%s+$", "")

	local user_path = os.getenv("PATH") or ""
	local prefix = ""
	if llvm_bin ~= "" then
		prefix = 'env PATH="' .. llvm_bin .. ":" .. user_path .. '" '
	end

	return prefix, "LLVM=1 "
end

function M.build()
	if not exec.path_exists(KERNEL_DIR) then
		colors.error(KERNEL_DIR .. " doesn't exist -- is your kernel source linked there?")
		return false, 1, nil
	end

	local kver = exec.capture("cd " .. KERNEL_DIR .. " && make kernelrelease 2>/dev/null"):gsub("%s+$", "")
	if kver == "" then
		colors.error("couldn't determine kernel release -- is the source tree configured (make menuconfig)?")
		return false, 1, nil
	end

	colors.neon_tag(">>> building " .. kver)

	local env_prefix, make_flag = compiler_args()
	local jobs = exec.capture("nproc"):gsub("%s+$", "")
	if jobs == "" then
		jobs = "1"
	end

	local function step_cmd(target)
		local inner = "cd " .. KERNEL_DIR .. " && " .. env_prefix .. target
		return "sh -c '" .. inner .. "'"
	end

	local steps = {
		{ cmd = step_cmd("nice -n 10 make " .. make_flag .. "-j" .. jobs), label = "compile" },
		{ cmd = step_cmd("make " .. make_flag .. "modules_install"), label = "modules_install" },
		{ cmd = step_cmd("make " .. make_flag .. "install"), label = "kernel install" },
		{ cmd = "dracut --force --kver " .. kver, label = "initramfs" },
	}

	for _, step in ipairs(steps) do
		local ok, code = sudo.run(step.cmd, { label = step.label })
		if not ok then
			return false, code, kver
		end
	end

	return true, 0, kver
end

function M.update_bootloader()
	local cfg = config.load()

	if cfg.bootloader == "limine" then
		colors.info("limine picks up new kernels on its own -- nothing to regenerate")
		return true, 0
	end

	return sudo.run("grub-mkconfig -o /boot/grub/grub.cfg", { label = "grub config" })
end
function M.find_stale_modules()
	local running = exec.capture("uname -r"):gsub("%s+$", "")
	local out = exec.capture("ls /lib/modules 2>/dev/null")
	local stale = {}
	for name in out:gmatch("[^\n]+") do
		if name ~= running then
			table.insert(stale, name)
		end
	end
	return stale, running
end

function M.remove_modules(version)
	return sudo.run('rm -rf "/lib/modules/' .. version .. '"', { label = "remove " .. version })
end

return M
