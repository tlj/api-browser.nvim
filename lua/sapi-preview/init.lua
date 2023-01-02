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
  package = '',
  base_url = '',
  keep_state = true,
  -- base_urls should not be set and pushed to github, use
  -- environment variable SAPI_PREVIEW_URLS instead
  base_urls = {}
}

local endpoints = {}
local packages = {}

M.setup = function(opts)
  opts = opts or {}

  if opts.base_urls ~= nil and next(opts.base_urls) ~= nil then
    print("Warning: base_urls should be set with env variable SAPI_PREVIEW_URLS, semicolon separated.")
  end

  M.options = {}
  for k, v in pairs(default) do
    M.options[k] = v
  end

  local base_urls = os.getenv("SAPI_PREVIEW_URLS")
  if base_urls ~= nil then
    for str in string.gmatch(base_urls, "([^;]+)") do
      table.insert(M.options.base_urls, str)
    end
  else
    print("SAPI_PREVIEW_URLS is empty.")
  end

  for k, v in pairs(opts) do
    M.options[k] = v
  end

  if M.options.keep_state then
    for k, _ in pairs(default) do
      local v = db.get_default(k)
      if v ~= nil then
        M.options[k] = v
      end
    end
  end

  if M.options.base_url == "" then
    local bu = M.options.base_urls[1]
    if bu ~= nil then
      M.options.base_url = bu
    end
  end
end

local function update_packages()
  packages = db.get_packages()
  if next(packages) == nil then
    M.refresh_packages()
    packages = db.get_packages()
  end
end

M.refresh_packages = function(opts)
  opts = opts or {}

  local routes_url = M.options.base_url .. "/routes.json"
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

M.select_package = function(opts)
  opts = opts or {}

  if next(packages) == nil then
    update_packages()
  end

  pickers.new(opts, {
    prompt_title = "Select a package (" .. M.options.base_url .. ")",
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

        endpoints = {}

        M.options.package = selection.value.name .. "/" .. selection.value.version .. "/en"
        db.set_default("package", M.options.package)
      end)
      return true
    end
  }):find()
end

M.select_base_url = function(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Select a base URL",
    finder = finders.new_table {
      results = M.options.base_urls,
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

        M.options.base_url = selection[1]
        db.set_default("base_url", M.options.base_url)
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
    prompt_title = "Endpoints for urn " .. txt .. " (" .. M.options.base_url .. ")",
    finder = finders.new_table {
      results = urn_endpoints,
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

        db.push_history(selection[1])

        vim.api.nvim_command('botright vnew')
        local buf = vim.api.nvim_get_current_buf()
        vim.schedule(function()
          fetch.fetch_and_display(M.options.base_url .. selection[1], {buf = buf})
        end)
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
    prompt_title = "",
    finder = finders.new_table {
      results = urls,
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

        db.push_history(selection[1])
        vim.api.nvim_command('botright vnew')
        local buf = vim.api.nvim_get_current_buf()
        vim.schedule(function()
          fetch.fetch_and_display(M.options.base_url .. selection[1], {buf = buf})
        end)
      end)
      return true
    end
  }):find()
end

M.update_endpoints = function(opts)
  opts = opts or {}

  if M.options.package == nil or M.options.package == "" then
    error("No package selected, please select a package first.")
    return
  end

  endpoints = { examples = {}, requirements = {} }
  local cached_endpoints = db.get_package_endpoints(M.options.package)
  if next(cached_endpoints) ~= nil then
    for _, v in pairs(cached_endpoints) do
      table.insert(endpoints.examples, v.url)
    end
    local cached_requirements = db.get_package_requirements(M.options.package)
    for _, v in pairs(cached_requirements) do
      endpoints.requirements[v.name] = v.value
    end
    return
  end

  local routes_url = M.options.base_url .. "/" .. M.options.package .. "/routes.json"
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
    db.add_package_requirement(M.options.package, k, v)
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
    db.add_package_endpoint(M.options.package, json_endpoint)
    table.insert(endpoints.examples, xml_endpoint)
    db.add_package_endpoint(M.options.package, xml_endpoint)
  end
end

M.endpoints = function(opts)
  opts = opts or {}

  if endpoints.examples == nil then
    print("No examples, updating endpoints")
    M.update_endpoints(opts)
  end

  pickers.new(opts, {
    prompt_title = "Endpoints (" .. M.options.base_url .. ")",
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

        db.push_history(selection[1])

        vim.api.nvim_command('botright vnew')
        local buf = vim.api.nvim_get_current_buf()
        vim.schedule(function()
          fetch.fetch_and_display(fetchUrl, {buf = buf})
        end)
      end)

      return true
    end
  }):find()
end

return M


