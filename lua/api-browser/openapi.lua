local conf = require("api-browser.config")

local M = {
  url = '',
  json = {
    paths = {},
    servers = {},
    components = {
      parameters = {},
    }
  }
}

local function compare_endpoints(a, b)
  return a.url < b.url
end

M.load = function()
  M.parse_file(conf.get_selected_api())
end

M.get_apis = function()
  local workspace = vim.fn.getcwd()
  local workspace_esc = string.gsub(workspace, "%-", "%%-") .. "/"
  local result = {}

  for _, file in ipairs(vim.fn.glob(workspace .. "**/openapi.json", true, true)) do
    table.insert(result, { name = string.gsub(file, workspace_esc, "") })
  end

  return result
end

M.replace_placeholder = function(endpoint, name, value, params)
  local rr = vim.deepcopy(endpoint)
  rr.replaced = rr.replaced or {}
  rr.url = rr.url:gsub("{" .. name .."}", value)
  rr.replaced[name] = value

  return M.replace_placeholders(rr, params)
end

M.replace_placeholders = function(endpoint, in_params)
  -- make a copy of the params since we are manipulating it
  local params = vim.deepcopy(in_params)
  -- get the first param
  local fk, fv = next(params)
  -- if the param key is nil, then return the endpoint
  if fk == nil then
    return {endpoint}
  end

  -- remove the param from the list since we are handing it here
  params[fk] = nil

  -- if the param is not a path param, or not in the path, then go to next param
  if fv["in"] ~= "path" or not endpoint.url:find(fv.name) then
    return M.replace_placeholders(endpoint, params)
  end

  -- Since the param is a path param, then we need to replace it in the url
  local result = {}

  -- replace the path param with the default or enum value if it exists
  if endpoint.url:find(fv.name) then
    if fv.schema.default then
      -- if we have a default, we also add the path with placeholder
      local rd = vim.deepcopy(endpoint)
      local new = M.replace_placeholders(rd, params)
      for _, n in pairs(new) do
        table.insert(result, n)
      end

      -- if we have a default we only expand that
      new = M.replace_placeholder(endpoint, fv.name, fv.schema.default, params)
      for _, n in pairs(new) do
        table.insert(result, n)
      end
    elseif fv.schema.enum then
      -- if we have an enum we expand all of them
      for _, e in pairs(fv.schema.enum) do
        local new = M.replace_placeholder(endpoint, fv.name, e, params)
        for _, n in pairs(new) do
          table.insert(result, n)
        end
      end
    end
  end

  -- return our endpoints, replaced or not
  table.sort(result, compare_endpoints)
  return result
end

M.parse_endpoints = function()
  local defaults = M.json.components.parameters
  local result = {}

  for path, _ in pairs(M.json.paths or {}) do
    local res = {
      original_url = path,
      url = path,
      api = '',
      placeholders = {},
      requirements = {},
      replaced = {},
    }
    local expanded = M.replace_placeholders(res, defaults)
    for _, r in pairs(expanded) do
      table.insert(result, r)
    end
  end

  table.sort(result, compare_endpoints)
  return result
end

M.get_servers = function()
  local result = {}

  for _, server in pairs(M.json.servers or {}) do
    table.insert(result, {
      name = server.description or server.url,
      url = server.url,
    })
  end

  return result
end

M.get_server = function(description)
  for _, server in pairs(M.json.servers or {}) do
    if server.description == description then
      return server.url
    end
  end

  vim.print("No server found with description " .. description .. ".")
  return ""
end

M.split_ref = function(inputstr)
  local sep = "/"
  local t={}

  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end

  table.remove(t, 1)

  return t
end

M.lookup_ref = function(base, refs)
  -- get first part of the path
  local first = table.remove(refs, 1)

  -- if this is the last reference, then return the value
  if next(refs) == nil then
    return base[first]
  end

  -- continue checking the refs since there is more in the path
  return M.lookup_ref(base[first], refs)
end

M.resolve = function(k, v)
  if k == "$ref" then
    return M.lookup_ref(M.json, M.split_ref(v))
  end
  if type(v) == "table" then
    for k1, v1 in pairs(v) do
      if k1 == "$ref" then
        v[k] = M.resolve(k1, v1)
        v[k1] = nil
      else
        v[k1] = M.resolve(k1, v1)
      end
    end
  end
  return v
end

M.parse = function(content)
  M.json = vim.fn.json_decode(content)
  for k, v in pairs(M.json.paths or {}) do
    M.json.paths[k] = M.resolve(k, v)
  end
end

M.parse_file = function(file_name)
  local f = io.open(file_name, "r")
  if not f then
    error("Unable to read file " .. file_name .. ".")
    return
  end
  local content = f:read("*all")

  M.parse(content)
end

return M
