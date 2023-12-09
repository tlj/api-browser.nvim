local M = {}

M.setup = function()
  local config = require("api-browser.config")
  local openapi = require("api-browser.openapi")
  config.setup()

  if config.get_selected_api() then
    openapi.parse_file(config.get_selected_api())
  end
end

M.select_api = require("api-browser.cmds.select_api").select_api
M.select_server = require("api-browser.cmds.select_server").select_server
M.select_remote_server = require("api-browser.cmds.select_remote_server").select_remote_server
M.endpoint_with_urn = require("api-browser.cmds.endpoint_with_urn").endpoint_with_urn
M.recents = require("api-browser.cmds.recents").recents
M.endpoints = require("api-browser.cmds.endpoints").endpoints
--[[
M.update_endpoints = require("api-browser.endpoints").load
--]]

return M

