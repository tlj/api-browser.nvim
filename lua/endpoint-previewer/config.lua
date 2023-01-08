local db = require("endpoint-previewer.db")

local M = {
  options = {
    keep_state = true,
    selected_api = '',
    selected_env = 'dev',
    selected_remote_env = 'prod',
    env_base_urls = {},
    endpoints_url_path = '/endpoints.json',
    endpoints_file = '',
  },
}

M.set_options = function (opts)
  M.options = opts
end

M.set_selected_api = function(api)
  M.options.selected_api = api
end

M.get_selected_api = function()
  return M.options.selected_api
end

M.get_selected_env = function()
  return M.options.selected_env
end

M.get_selected_remote_env = function()
  return M.options.selected_remote_env
end

M.endpoints_file = function()
  return M.options.endpoints_file
end

M.endpoints_url = function()
  return M.selected_base_url() .. M.options.endpoints_url_path
end

M.set_selected_env = function(env)
  M.options.selected_env = env
  db.set_default('selected_env', env)
end

M.set_selected_remote_env = function(env)
  M.options.selected_remote_env = env
  db.set_default('selected_remote_env', env)
end

M.selected_base_url = function()
  return M.options.env_base_urls[M.options.selected_env]
end

M.selected_remote_base_url = function()
  return M.options.env_base_urls[M.options.selected_remote_env]
end

M.get_environments = function()
  local result = {}
  for k, v in pairs(M.options.env_base_urls or {}) do
    table.insert(result, { name = k, url = v })
  end
  return result
end

M.setup = function(opts)
  opts = opts or {}

  local options = M.options

  for k, v in pairs(opts) do
    options[k] = v
  end

  local base_urls = os.getenv("ENDPOINT_PREVIEWER_URLS")
  if base_urls ~= nil then
    for str in string.gmatch(base_urls, "([^;]+)") do
      local split_result = {}
      for m in string.gmatch(str, "([^=]+)") do
        table.insert(split_result, m)
      end
      options.env_base_urls[split_result[1]] = split_result[2]
    end
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

