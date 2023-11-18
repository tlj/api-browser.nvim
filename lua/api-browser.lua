local M = {}

M.setup = require("api-browser.config").setup

M.select_api = require("api-browser.cmds.select_api").select_api
M.select_env = require("api-browser.cmds.select_env").select_env
M.select_remote_env = require("api-browser.cmds.select_remote_env").select_remote_env
M.endpoint_with_urn = require("api-browser.cmds.endpoint_with_urn").endpoint_with_urn
M.recents = require("api-browser.cmds.recents").recents
M.update_endpoints = require("api-browser.endpoints").load
M.endpoints = require("api-browser.cmds.endpoints").endpoints

return M

