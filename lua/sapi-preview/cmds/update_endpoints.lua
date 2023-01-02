local conf = require("sapi-preview.config")
local db = require("sapi-preview.db")
local curl = require("sapi-preview.curl")

local M = {}

M.update_endpoints = function(opts)
  opts = opts or {}

  if conf.options.package == nil or conf.options.package == "" then
    error("No package selected, please select a package first.")
    return
  end

  local endpoints = { examples = {}, requirements = {} }
  local cached_endpoints = db.get_package_endpoints(conf.options.package)
  if next(cached_endpoints) ~= nil then
    for _, v in pairs(cached_endpoints) do
      table.insert(endpoints.examples, v.url)
    end
    local cached_requirements = db.get_package_requirements(conf.options.package)
    for _, v in pairs(cached_requirements) do
      endpoints.requirements[v.name] = v.value
    end
    conf.set_endpoints(endpoints)
    return
  end

  local routes_url = conf.options.base_url .. "/" .. conf.options.package .. "/routes.json"
  local curl_result = curl.fetch(routes_url, {})
  if curl_result == nil then
    error("Error fetching " .. routes_url)
    return
  end

  if curl_result.status ~= 200 then
    error(routes_url .. " returned status code " .. curl_result.status)
    return
  end

  endpoints = vim.fn.json_decode(curl_result.body)
  endpoints.examples = {}

  if endpoints == nil or endpoints.routes == nil then
    error("Unable to parse routes.json (" .. routes_url .. ")")
    return
  end

  for k, v in pairs(endpoints.requirements) do
    db.add_package_requirement(conf.options.package, k, v)
  end

  for k, v in pairs(endpoints.routes) do
    for id_placeholder in string.gmatch(v, '{_(%a+)}') do
      local def = endpoints.defaults[k]["_" ..id_placeholder]
      if def ~= nil and id_placeholder ~= "format" then
        v = v:gsub("{_" .. id_placeholder .. "}", def)
      end
    end

    local json_endpoint, _ = v:gsub("{_format}", ".json")
    local xml_endpoint, _ = v:gsub("{_format}", ".xml")
    table.insert(endpoints.examples, json_endpoint)
    db.add_package_endpoint(conf.options.package, json_endpoint)
    table.insert(endpoints.examples, xml_endpoint)
    db.add_package_endpoint(conf.options.package, xml_endpoint)
  end

  conf.set_endpoints(endpoints)
end


return M
