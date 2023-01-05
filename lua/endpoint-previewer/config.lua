local db = require("endpoint-previewer.db")

local M = {
  options = {},
  endpoints = {},
  packages = {},
  package = '',
}

local default = {
  package = '',
  base_url = '',
  keep_state = true,
  -- base_urls should not be set and pushed to github, use
  -- environment variable ENDPOINT_PREVIEWER_URLS instead
  base_urls = {}
}

M.set_options = function (opts)
  M.options = opts
end

M.set_endpoints = function (endpoints)
  M.endpoints = endpoints
end

M.set_packages = function(packages)
  M.packages = packages
end

M.set_package = function(package)
  M.options.package = package
end

M.set_base_url = function(base_url)
  M.options.base_url = base_url
  require("endpoint-previewer.endpoints").set_url(base_url .. "/endpoints.json")
end

M.setup = function(opts)
  opts = opts or {}

  if opts.base_urls ~= nil and next(opts.base_urls) ~= nil then
    print("Warning: base_urls should be set with env variable ENDPOINT_PREVIEWER_URLS, semicolon separated.")
  end

  local options = {}
  for k, v in pairs(default) do
    options[k] = v
  end

  local base_urls = os.getenv("ENDPOINT_PREVIEWER_URLS")
  if base_urls ~= nil then
    for str in string.gmatch(base_urls, "([^;]+)") do
      table.insert(options.base_urls, str)
    end
  else
    print("ENDPOINT_PREVIEWER_URLS is empty.")
  end

  for k, v in pairs(opts) do
    options[k] = v
  end

  if options.keep_state then
    for k, _ in pairs(default) do
      local v = db.get_default(k)
      if v ~= nil then
        options[k] = v
      end
    end
  end

  if options.base_url == "" then
    local bu = options.base_urls[1]
    if bu ~= nil then
      M.set_base_url(bu)
    end
  else
    M.set_base_url(options.base_url)
  end

  M.options = options
end


return M
