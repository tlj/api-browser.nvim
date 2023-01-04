local M = {}

M.setup = require("endpoint-previewer.config").setup

M.select_api = require("endpoint-previewer.cmds.select_api").select_api
M.select_base_url = require("endpoint-previewer.cmds.select_base_url").select_base_url
M.endpoint_with_urn = require("endpoint-previewer.cmds.endpoint_with_urn").endpoint_with_urn
M.recents = require("endpoint-previewer.cmds.recents").recents
M.update_endpoints = require("endpoint-previewer.endpoints").load
M.endpoints = require("endpoint-previewer.cmds.endpoints").endpoints

return M

