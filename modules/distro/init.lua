
local config = require("lib.config")
local colors = require("lib.colors")

local cfg = config.load()

if not cfg.distro or cfg.distro == "" then
	colors.error("no distro configured -- run `baka init` first")
	os.exit(1)
end

if cfg.distro == "arch" then
	return require("modules.distro.arch")
elseif cfg.distro == "gentoo" then
	return require("modules.distro.gentoo")
else
	colors.error("unknown distro '" .. cfg.distro .. "' in config -- re-run `baka init`")
	os.exit(1)
end
