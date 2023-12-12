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
  if a.display_name and b.display_name then
    return a.display_name < b.display_name
  end
  return a.url < b.url
end

M.load = function()
  M.parse_file(conf.get_selected_api())
end

M.get_extension = function(file_name)
  return file_name:match("[^.]+$")
end

M.get_apis = function()
  local workspace = vim.fn.getcwd()
  local workspace_esc = string.gsub(workspace, "%-", "%%-") .. "/"
  local result = {}

  for _, pattern in ipairs(conf.options.patterns or {}) do
    for _, file in ipairs(vim.fn.glob(workspace .. pattern, true, true)) do
      table.insert(result, { name = string.gsub(file, workspace_esc, "") })
    end
  end

  return result
end

M.replace_placeholder = function(endpoint, name, value, params)
  local rr = vim.deepcopy(endpoint)
  rr.replaced = rr.replaced or {}
  value = tostring(value)
  rr.url = rr.url:gsub("{" .. name .."}", value)
  rr.replaced[name] = value
  rr.placeholders[name] = nil

  return M.replace_placeholders(rr, params)
end

M.explode_query_parameters = function(endpoint, in_params)
  local rr = vim.deepcopy(endpoint)
  local separator = "?"
  local names = {}
  for n in pairs(in_params) do table.insert(names, n) end
  table.sort(names)
  for _, n in ipairs(names) do
    local p = in_params[n]
    if p["in"] == "query" then
      if rr.url:find("?") then
        separator = "&"
      end
      rr.url = rr.url .. separator .. p.name .. "={" .. p.name .. "}"
    end
  end

  return rr
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
  if (fv["in"] ~= "path" and fv["in"] ~= "query") or not endpoint.url:find(fv.name) then
    return M.replace_placeholders(endpoint, params)
  end

  -- Since the param is a path param, then we need to replace it in the url
  local result = {}

  -- replace the path param with the default or enum value if it exists
  if endpoint.url:find(fv.name) and fv.schema then
    if fv.schema.default or fv.schema.example or fv.example then
      -- if we have a default, we also add the path with placeholder
      local rd = vim.deepcopy(endpoint)
      local new = M.replace_placeholders(rd, params)
      for _, n in pairs(new) do
        table.insert(result, n)
      end

      -- use example, unless default is set
      local val = fv.schema.example or fv.example
      if fv.schema.default then
        val = fv.schema.default
      end

      -- if we have a default we only expand that
      new = M.replace_placeholder(endpoint, fv.name, val, params)
      for _, n in pairs(new) do
        table.insert(result, n)
      end
    elseif fv.schema.enum then
      -- if we have an enum we expand all of them unless we have a default or example
      for _, e in pairs(fv.schema.enum) do
        local new = M.replace_placeholder(endpoint, fv.name, e, params)
        for _, n in pairs(new) do
          table.insert(result, n)
        end
      end
    else
      -- if we have no default or enum, then we skip this param
      return M.replace_placeholders(endpoint, params)
    end
  else
    -- if we have no schema, then we skip this param
    return M.replace_placeholders(endpoint, params)
  end

  -- return our endpoints, replaced or not
  table.sort(result, compare_endpoints)
  return result
end

M.endpoint_display_name = function(endpoint)
  local name = endpoint.url

  if endpoint.headers['Accept'] then
    name = name .. " (" .. endpoint.headers['Accept'] .. ")"
  end

  return name
end

M.parse_endpoints = function()
  local result = {}

  for path, info in pairs(M.json.paths or {}) do
    if info.get then
      local res = {
        original_url = path,
        url = path,
        api = '',
        display_name = path,
        placeholders = {},
        requirements = {},
        replaced = {},
        headers = {},
      }
      local exploded = M.explode_query_parameters(res, info.get.parameters or {})
      local expanded = M.replace_placeholders(exploded, info.get.parameters or {})
      for _, r in pairs(expanded) do
        for _, p in pairs(info.get.parameters or {}) do
          if not r.replaced[p.name] then
            if p["schema"] then
              if p["schema"].pattern then
                r.placeholders[p.name] = p["schema"].pattern
              elseif p["schema"].type == "integer" and p["schema"].format == "int64" then
                r.placeholders[p.name] = "^\\d+$"
              elseif p["schema"].type == "string" and p["schema"].enum and type(p["schema"].enum) == "table" then
                local pattern = {}

                for _, n in pairs(p["schema"].enum) do
                  table.insert(pattern, n)
                end

                r.placeholders[p.name] = pattern
              end
            end
          end
        end

        if info.get.responses and info.get.responses["200"] then
          for rt in pairs(info.get.responses["200"].content) do
            local rc = vim.deepcopy(r)
            rc.headers["Accept"] = rt
            table.insert(result, rc)
          end
        else
          table.insert(result, r)
        end
      end
    end
  end

  for k, v in pairs(result) do
    result[k].display_name = M.endpoint_display_name(v)
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

M.get_endpoint_by_param_pattern = function(value)
  M.parse_file(conf.get_selected_api())
  local parsed_urls = M.parse_endpoints()
  if not parsed_urls then
    parsed_urls = {}
  end

  local matching_urls = {}
  for _, r in pairs(parsed_urls) do
    for paramName, pattern in pairs(r.placeholders) do
      if type(pattern) == "string" then
        pattern = pattern:gsub('\\d', '%%d')
      end
      if type(pattern) == "table" then
        for _, p in pairs(pattern) do
          if p == value then
            local ec = vim.deepcopy(r)
            ec.url = ec.url:gsub("{" .. paramName .. "}", value)
            ec.display_name = ec.display_name:gsub("{" .. paramName .. "}", value)
            ec.replaced[paramName] = value
            ec.placeholders[paramName] = nil
            table.insert(matching_urls, ec)
            break
          end
        end
      elseif value:find(pattern) then
        local ec = vim.deepcopy(r)
        ec.url = ec.url:gsub("{" .. paramName .. "}", value)
        ec.display_name = ec.display_name:gsub("{" .. paramName .. "}", value)
        ec.replaced[paramName] = value
        ec.placeholders[paramName] = nil
        table.insert(matching_urls, ec)
      end
    end
  end

  return matching_urls
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
      -- if a key in the table is a ref, then resolve it
      if k1 == "$ref" then
        v = M.resolve(k1, v1)
        break
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
  local ext = M.get_extension(file_name)
  local content = ""

  if file_name == "" or not vim.fn.filereadable(file_name) then
    return
  end

  if ext == "yaml" or ext == "yml" then
    local filename_esc = string.gsub(file_name, "%-", "%%-")
    local cmd = string.format("yq %s --output-format json 2>&1", filename_esc)
    local handle = io.popen(cmd, "r")
    content = handle:read("*a")
    handle:close()
  elseif ext == "json" then
    local f = io.open(file_name, "r")
    if not f then
      error("Unable to read file " .. file_name .. ".")
      return
    end
    content = f:read("*all")
  else
    error("Unknown file type " .. ext .. ".")
  end

  M.parse(content)
end

return M
