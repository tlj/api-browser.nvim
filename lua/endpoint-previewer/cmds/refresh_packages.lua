local curl = require("endpoint-previewer.curl")
local db = require("endpoint-previewer.db")
local conf = require("endpoint-previewer.config")

local M = {}

M.refresh_packages = function(opts)
  opts = opts or {}

  local routes_url = conf.options.base_url .. "/routes.json"
  local curl_result = curl.fetch(routes_url, {})
  if curl_result.status ~= 200 then
    error("Got status code " .. curl_result.status .. " when fetching base routes.json.")
    return
  end

  local body = vim.fn.json_decode(curl_result.body)

  for _, value in pairs(body.routes) do
    if value.defaults ~= nil and value.defaults.package_version ~= nil and value.defaults.package_version ~= "" and value.defaults.package_version ~= vim.NIL then
      db.add_package(value.defaults.package_name, value.defaults.package_version)
    end
  end
end

return M
