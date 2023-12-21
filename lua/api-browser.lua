local M = {}

M.setup = function(opts)
	local config = require("api-browser.config")
	local curl = require("api-browser.curl")
	local openapi = require("api-browser.openapi")

	config.setup(opts)
	curl.options = config.options.curl

	if config.get_selected_api() then
		openapi.parse_file(config.get_selected_api())
	end
end

M.open = require("api-browser.cmds.open").open
M.select_local_server = require("api-browser.cmds.select_local_server").select_local_server
M.select_remote_server = require("api-browser.cmds.select_remote_server").select_remote_server
M.endpoints_with_param = require("api-browser.cmds.endpoints_with_param").endpoints_with_param
M.recents = require("api-browser.cmds.recents").recents
M.endpoints = require("api-browser.cmds.endpoints").endpoints

return M
