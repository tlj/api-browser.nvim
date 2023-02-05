local curl = require("endpoint-previewer.curl")
local conf = require("endpoint-previewer.config")

local M = {
  loaded = false,
  url = '',
  json = {
    apis = {},
    global = {
      endpoints = {},
      requirements = {},
      defaults = {}
    }
  }
}

local function compare_endpoints(a, b)
  return a.url < b.url
end

M.is_loaded = function()
  return M.loaded
end

M.set_url = function(url)
  M.url = url
  M.loaded = false
end

M.load = function()
  M.loaded = false
  if M.url == "" then
    if conf.endpoints_file() ~= "" then
      M.parse_file(conf.endpoints_file())
    else
      M.parse_url(conf.endpoints_url())
    end
  else
    M.parse_url(M.url)
  end
end

M.get_api_names = function()
  if not M.is_loaded() then M.load() end

  local result = {}
  for k, _ in pairs(M.json.apis) do
    table.insert(result, k)
  end

  table.sort(result)

  return result
end

M.get_apis = function()
  if not M.is_loaded() then M.load() end

  local result = {}
  for k, v in pairs(M.json.apis) do
    table.insert(result, {
      name = k,
      package = v.package,
      version = v.version,
    })
  end

  return result
end

M.get_endpoint_by_api_name_and_urn = function(api_name, urn)
  if not M.is_loaded() then M.load() end

  local endpoints = M.get_by_api_name(api_name)
  if not endpoints then
    return {}
  end
  local result = {}
  for _, e in pairs(endpoints) do
    for p, r in pairs(e.requirements or {}) do
      r = r:gsub('\\d', '%%d')
      if urn:find(r) then
        local ec = vim.deepcopy(e)
        ec.matches_placeholder = p
        ec.url = ec.url:gsub("{" .. p .. "}", urn)
        local placeholder_idx = 0
        for k, v in pairs(ec.placeholders) do
          if v == p then placeholder_idx = k end
        end
        if placeholder_idx > 0 then table.remove(ec.placeholders, placeholder_idx) end
        table.insert(result, ec)
      end
    end
  end

  table.sort(result, compare_endpoints)

  return result
end

M.replace_with_defaults = function(endpoint, defaults)
  local defs = vim.deepcopy(defaults)
  local fk, fv = next(defs)
  if fk == nil then
    return {endpoint}
  end
  defs[fk] = nil

  if not endpoint.url:find(fk) then
    return M.replace_with_defaults(endpoint, defs)
  end

  local result = {}
  for _, v in pairs(fv) do
    local rr = vim.deepcopy(endpoint)
    rr.replaced = rr.replaced or {}
    if endpoint.url:find(fk) then
      rr.url = rr.url:gsub("{" .. fk .."}", v)
      rr.replaced[fk] = v
    end
    local new = M.replace_with_defaults(rr, defs)
    for _, n in pairs(new) do
      table.insert(result, n)
    end
  end

  return result
end

M.parse_endpoints = function(endpoints, defaults, requirements)
  local result = {}
  for _, endpoint in pairs(endpoints or {}) do
    local defs = vim.deepcopy(defaults)
    for k, d in pairs(endpoint.defaults or {}) do
      defs[k] = d
    end

    local reqs = vim.deepcopy(requirements)
    for k, d in pairs(endpoint.requirements or {}) do
      reqs[k] = d
    end

    local res = {
      original_url = endpoint.url,
      url = endpoint.url,
      api = "",
      placeholders = {},
      requirements = {},
      replaced = {},
    }

    local replaced = M.replace_with_defaults(res, defs)
    for _, r in pairs(replaced) do
      for ph in r.url:gmatch("{(%a+)}") do
        table.insert(r.placeholders, ph)
        if reqs[ph] ~= nil then
          r.requirements[ph] = reqs[ph]
        end
      end
      table.insert(result, r)
    end
  end

  return result
end

M.get_by_api_name = function(api_name, opts)
  if not M.is_loaded() then M.load() end

  opts = opts or {}

  if api_name ~= "" and (M.json.apis and M.json.apis[api_name] == nil) then
    return nil
  end

  local result = {}
  if not opts.noglobal then
    result = M.parse_endpoints(M.json.global.endpoints, M.json.global.defaults, M.json.global.requirements)
  end

  if api_name ~= "" then
    local api_defaults = M.json.global.defaults or {}
    for k, v in pairs(M.json.apis[api_name].defaults or {}) do
      api_defaults[k] = v
    end
    local api_requirements = M.json.global.requirements or {}
    for k, v in pairs(M.json.apis[api_name].requirements or {}) do
      api_requirements[k] = v
    end

    local result_api = M.parse_endpoints(M.json.apis[api_name].endpoints, api_defaults, api_requirements)
    for _, v in pairs(result_api) do
      v.api = api_name
      table.insert(result, v)
    end
  end

  table.sort(result, compare_endpoints)

  return result
end

M.parse = function(content)
  M.json = vim.fn.json_decode(content)
  M.loaded = true
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

M.parse_url = function(url)
  local curl_result = curl.fetch(url, {})
  if curl_result.status ~= 200 then
    error("Got status code " .. curl_result.status .. " when fetching base routes.json.")
    return
  end

  M.parse(curl_result.body)
end

return M
