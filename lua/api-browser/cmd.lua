local M = {}

M.load_command = function(cmd, _)
	if cmd == nil then
		return
	end

	local commands = {
		["open"] = require("api-browser").open,
		["select_local_server"] = require("api-browser").select_local_server,
		["select_remote_server"] = require("api-browser").select_remote_server,
		["recents"] = require("api-browser").recents,
		["endpoints"] = require("api-browser").endpoints,
		["endpoints_with_param"] = require("api-browser").endpoints_with_param,
	}

	for c in pairs(commands) do
		if c == cmd then
			commands[c]()
			return
		end
	end

	vim.print("Invalid command " .. cmd)
end

return M
