
local M = {}

M.init      = require("commands.setup").run
M.help      = require("commands.help").run
M.status    = require("commands.status").run
M.rebuild   = require("commands.rebuild").run
M.update    = require("commands.update").run
M.clean     = require("commands.clean").run
M.backup    = require("commands.backup").run
M.why       = require("commands.why").run
M.files     = require("commands.files").run
M.ports     = require("commands.ports").run
M.network   = require("commands.network").run
M.storage   = require("commands.storage").run
M.kernel    = require("commands.kernel").run
M.services  = require("commands.services").run
M.temp      = require("commands.temp").run
M.battery   = require("commands.battery").run
M.cpu       = require("commands.cpu").run
M.doctor    = require("commands.doctor").run
M.todo      = require("commands.todo").run
M.speedtest = require("commands.speedtest").run
M.inspect   = require("commands.inspect").run

return M
