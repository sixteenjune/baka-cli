-- commands/init.lua
-- THIS IS THE COMMAND REGISTRY, NOT THE `baka init` COMMAND.
--
-- It's named init.lua only because a directory containing init.lua is
-- how Lua resolves `require("commands")` -- that's the whole reason this
-- file exists. The actual `baka init` setup wizard lives in
-- commands/setup.lua and is registered below as M.init.
--
-- Every command module is required eagerly (right here), but none of
-- them may do config-dependent work at their own top level -- see the
-- comment in commands/_template.lua for why.

local M = {}

M.init    = require("commands.setup").run
M.help    = require("commands.help").run
M.status  = require("commands.status").run
M.rebuild = require("commands.rebuild").run
M.update  = require("commands.update").run
M.clean   = require("commands.clean").run
M.backup  = require("commands.backup").run
M.why     = require("commands.why").run
M.files   = require("commands.files").run
M.ports   = require("commands.ports").run
M.network = require("commands.network").run
M.storage = require("commands.storage").run

return M
