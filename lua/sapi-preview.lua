local M = {}

M.setup = require("sapi-preview.config").setup

M.refresh_packages = require("sapi-preview.cmds.refresh_packages").refresh_packages
M.select_package = require("sapi-preview.cmds.select_package").select_package
M.select_base_url = require("sapi-preview.cmds.select_base_url").select_base_url
M.endpoint_with_urn = require("sapi-preview.cmds.endpoint_with_urn").endpoint_with_urn
M.recents = require("sapi-preview.cmds.recents").recents
M.update_endpoints = require("sapi-preview.cmds.update_endpoints").update_endpoints
M.endpoints = require("sapi-preview.cmds.endpoints").endpoints

return M

