local db = require("api-browser.db")

local M = {
  options = {
    keep_state = true,
    selected_api = '',
    selected_env = 'dev',
    selected_remote_env = 'prod',
    env_base_urls = {},
    endpoints_url_path = '/endpoints.json',
    endpoints_file = '',
    openapi_url_path = '/openapi.json',
    openapi_file = '',
    selected_server = {},
    selected_remote_server = {},
  },
}

M.set_options = function (opts)
  M.options = opts
end

M.set_selected_api = function(api)
  M.options.selected_api = api
  db.set_default('selected_api', api)
end

M.get_selected_api = function()
  return M.options.selected_api
end

M.set_selected_server = function(server)
  db.set_default('selected_server', server)
  M.options.selected_server = server
end

M.get_selected_server = function()
  return M.options.selected_server
end

M.set_selected_remote_server = function(server)
  db.set_default('selected_remote_server', server)
  M.options.selected_remote_server = server
end

M.get_selected_remote_server = function()
  return M.options.selected_remote_server
end

M.setup = function(opts)
  opts = opts or {}

  local options = M.options

  for k, v in pairs(opts) do
    options[k] = v
  end

  if options.keep_state then
    for k, _ in pairs(M.options) do
      local v = db.get_default(k)
      if v ~= nil then
        options[k] = v
      end
    end
  end

  M.options = options
end

return M

