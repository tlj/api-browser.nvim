local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local tele_utils = require "telescope.utils"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local ts_utils = require "nvim-treesitter.ts_utils"
local conf = require("telescope.config").values
local utils = require("sapi-preview.utils")
local curl = require("sapi-preview.curl")
local db = require("sapi-preview.db")
local fetch = require("sapi-preview.fetch")

local M = {}
local default = {
  package = 'soccer-europe/v3/en',
  base_url = 'http://localhost:8061',
}

local endpoints = {
}

M.setup = function(opts)
  opts = opts or {}

  M.options = {}
  for k, v in pairs(default) do
    M.options[k] = v
  end

  for k, v in pairs(opts) do
    M.options[k] = v
  end
end

local packages = {}
M.update_packages = function(opts)
  opts = opts or {}

  local routes_url = M.options.base_url .. "/routes.json"
  local curl_result = curl.fetch(routes_url, {})
  local body = vim.fn.json_decode(curl_result.body)

  for key, value in pairs(body.routes) do
    if value.defaults ~= nil and value.defaults.package_version ~= nil and value.defaults.package_version ~= "" and value.defaults.package_version ~= vim.NIL then
      table.insert(packages, {name = value.defaults.package_name, version = value.defaults.package_version})
    end
  end
end

M.select_package = function(opts)
  opts = opts or {}

  if next(packages) == nil then
    M.update_packages()
  end

  pickers.new(opts, {
    prompt_title = "Select a package",
    finder = finders.new_table {
      results = packages,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name .. " " .. entry.version,
          ordinal = entry.name .. " " .. entry.version,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(fbuf, attmap)
      actions.select_default:replace(function()
        actions.close(fbuf)
        local selection = action_state.get_selected_entry()
        if not selection then
          tele_utils.__warn_no_selection "builtin.builtin"
          return
        end

        M.options.package = selection.value.name .. "/" .. selection.value.version .. "/en"
        endpoints = {}
        print("Package prefix set to " .. M.options.package)
      end)
      return true
    end
  }):find()
end

M.endpoint_with_urn = function(opts)
  local node = ts_utils.get_node_at_cursor()
  if node == nil then
    error("No Treesitter parser found.")
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local txt = vim.treesitter.query.get_node_text(node, bufnr)
  txt = txt:gsub('"','')

  if string.find(txt, "^sr:(%a+):%d+$") == nil then
    error("Not a valid SR URN: " .. txt)
    return
  end

  if endpoints.requirements == nil or endpoints.examples == nil then
    M.update_endpoints({})
  end

  local urn_types = {}
  for k, r in pairs(endpoints.requirements) do
    r = r:gsub('\\d', '%%d')
    local ptns = utils.split_regex(r)
    for _, p in pairs(ptns) do
      if string.find(txt, p) ~= nil and string.find(k, "^_") == nil then
        table.insert(urn_types, "{" .. k .. "}")
      end
    end
  end

  local urn_endpoints = {}
  for _, v in pairs(endpoints.examples) do
    local found = false
    for _, ptn in pairs(urn_types) do
      if string.find(v, ptn) ~= nil then
        v = v:gsub(ptn, txt)
        found = true
      end
    end
    if found then
      table.insert(urn_endpoints, v)
    end
  end
  pickers.new(opts, {
    prompt_title = "endpoints for urn " .. txt,
    finder = finders.new_table {
      results = urn_endpoints,
    },
    attach_mappings = function(fbuf, attmap)
      actions.select_default:replace(function()
        actions.close(fbuf)
        local selection = action_state.get_selected_entry()
        if not selection then
          tele_utils.__warn_no_selection "builtin.builtin"
          return
        end

        fetch.fetch_and_display(M.options.base_url .. selection[1], {})
      end)
      return true
    end
  }):find()
end

M.recents = function(opts)
  opts = opts or {}
  local entries = db.get_entries()
  table.sort(entries, function (k1, k2)
    return k1.last_used > k2.last_used
  end)
  local urls = utils.map(entries, function(entry)
    -- return { url = row.url, last_used = row.last_used }
    return entry.url
  end)
  pickers.new(opts, {
    prompt_title = "endpoint history",
    finder = finders.new_table {
      results = urls,
    },
    attach_mappings = function(fbuf, attmap)
      actions.select_default:replace(function()
        actions.close(fbuf)
        local selection = action_state.get_selected_entry()
        if not selection then
          tele_utils.__warn_no_selection "builtin.builtin"
          return
        end

        fetch.fetch_and_display(selection[1], {})
      end)
      return true
    end
  }):find()
end

M.update_endpoints = function(opts)
  opts = opts or {}

  local routes_url = M.options.base_url .. "/" .. M.options.package .. "/routes.json"
  local curl_result = curl.fetch(routes_url, {})

  endpoints = vim.fn.json_decode(curl_result.body)
  endpoints.examples = {}

  if endpoints == nil or endpoints.routes == nil then
    error("Unable to parse routes.json (" .. routes_url .. ")")
    return
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
    table.insert(endpoints.examples, xml_endpoint)
  end
end

M.endpoints = function(opts)
  opts = opts or {}

  if endpoints.examples == nil then
    M.update_endpoints(opts)
  end

  pickers.new(opts, {
    prompt_title = "endpoints",
    finder = finders.new_table {
      results = endpoints.examples,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(fbuf, attmap)
      actions.select_default:replace(function()
        actions.close(fbuf)

        local selection = action_state.get_selected_entry()
        if not selection then
          tele_utils.__warn_no_selection "builtin.builtin"
          return
        end

        local fetchUrl = M.options.base_url .. selection[1]
        for idPlaceHolder in string.gmatch(fetchUrl, '{(%a+)}') do
          vim.ui.input({
            prompt = idPlaceHolder .. ": ",
          }, function(idInput)
            fetchUrl = string.gsub(fetchUrl, "{" .. idPlaceHolder .. "}", idInput)
          end)
        end

        fetch.fetch_and_display(fetchUrl)
      end)

      return true
    end
  }):find()
end

return M


