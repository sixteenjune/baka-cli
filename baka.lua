#!/usr/bin/env lua

local handle = io.popen("dirname $(readlink -f '" .. arg[0] .. "')")
local script_dir = handle:read("*l") .. "/"
handle:close()

package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local commands = require("commands")

local cmd = arg[1]

if not cmd then
	print("usage: baka [command]")
elseif commands[cmd] then
	commands[cmd](arg)
else
	print("baka: unknown command")
end
