local db = require("api-browser.db")

local M = {
  options = {
    keep_state = true,
    state = {
      selected_api = '',
      selected_server = '',
      selected_remote_server = '',
    },
    ripgrep = {
      command = 'rg -l -g \'*.yaml\' -g \'*.json\' -e "openapi.*3"',
      no_ignore = false,
      fallback_globs = { "**/*.yaml", "**/*.json" },
    },
  },
}

M.set_options = function (opts)
  M.options = opts
end

M.set_selected_api = function(api)
  M.options.state.selected_api = api
  db.set_default('selected_api', api)
end

M.get_selected_api = function()
  return M.options.state.selected_api
end

M.set_selected_server = function(server)
  db.set_default('selected_server', server)
  M.options.state.selected_server = server
end

M.get_selected_server = function()
  return M.options.state.selected_server
end

M.set_selected_remote_server = function(server)
  db.set_default('selected_remote_server', server)
  M.options.state.selected_remote_server = server
end

M.get_selected_remote_server = function()
  return M.options.state.selected_remote_server
end

M.setup = function(opts)
  opts = opts or {}

  local options = M.options

  for k, v in pairs(opts) do
    options[k] = v
  end

  if options.keep_state then
    for k, _ in pairs(M.options.state) do
      local v = db.get_default(k)
      if v ~= nil then
        options.state[k] = v
      end
    end
  end

  M.options = options
end

return M

