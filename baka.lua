#!/usr/bin/env lua

local handle = io.popen("dirname $(readlink -f '" .. arg[0] .. "')")
local script_dir = handle:read("*l") .. "/"
handle:close()

package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local config = require("lib.config")
local colors = require("lib.colors")
local commands = require("commands")

local cmd = arg[1]

if not cmd then
	commands.help(arg)
	os.exit(0)
end

if cmd ~= "init" and not config.exists() then
	colors.warn("no config found -- run `baka init` first, baka")
end

if commands[cmd] then
	commands[cmd](arg)
else
	colors.error("'" .. cmd .. "' isn't a thing I know how to do -- try `baka help`")
	os.exit(1)
end
