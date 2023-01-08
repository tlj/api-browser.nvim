local M = {}

M.setup = require("endpoint-previewer.config").setup

M.select_api = require("endpoint-previewer.cmds.select_api").select_api
M.select_env = require("endpoint-previewer.cmds.select_env").select_env
M.select_remote_env = require("endpoint-previewer.cmds.select_remote_env").select_remote_env
M.endpoint_with_urn = require("endpoint-previewer.cmds.endpoint_with_urn").endpoint_with_urn
M.recents = require("endpoint-previewer.cmds.recents").recents
M.update_endpoints = require("endpoint-previewer.endpoints").load
M.endpoints = require("endpoint-previewer.cmds.endpoints").endpoints

return M

