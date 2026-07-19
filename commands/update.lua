local sudo = require("lib.sudo")

local M = {}

function M.run(arg)
	sudo.run("emerge --sync", { label = "sync" })
	sudo.run("emerge -uDNa @world", { label = "update" })
end

return M
