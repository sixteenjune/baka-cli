#!/usr/bin/env lua

local script_dir = arg[0]:match("(.*/)") or "./"
package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path

local commands = require("commands")

local cmd = arg[1]
if commands[cmd] then
	commands[cmd](arg)
else
	print("baka: unknown command")
end
