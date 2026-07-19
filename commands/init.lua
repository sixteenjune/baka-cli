local M = {}

M.rebuild = require("commands.rebuild").run
M.update = require("commands.update").run
M.init = require("commands.initialize").run
M.status = require("commands.status").run

return M
