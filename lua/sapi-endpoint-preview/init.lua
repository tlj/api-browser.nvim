local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local utils = require "telescope.utils"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local sqlite = require "sqlite"
local sqlite_uri = "/tmp/sapi_nvim_history.sqlite3"
local ts_utils = require "nvim-treesitter.ts_utils"

local conf = require("telescope.config").values
local endpoints = {}

local sapi = {}
local sapi_config = {
  package = "soccer-europe/v3/en",
  base_url = "http://localhost:8061"
}

local function ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

local function checkhealth()
  local has_sql, _ = pcall(require, "sqlite")
  if has_sql then
    vim.health.report_ok "sql.nvim installed."
  else
    vim.health.report_error "Need sql.vim to be installed."
  end
end

local db = sqlite {
  uri = sqlite_uri,
  entries = {
    id = true,
    url = "text",
    last_used = { "timestamp", default = sqlite.lib.strftime("%s", "now") }
  },
}

local function split_lines(body)
  local body_lines = {}
  for s in body:gmatch("[^\r\n]+") do
    table.insert(body_lines, s)
  end
  return body_lines
end

local function split_regex(ptn)
  local ptns = {}
  local size = 0
  for p in ptn:gmatch("[^|]+") do
    size = size + 1
    table.insert(ptns, p)
  end
  if size == 0 then
    table.insert(ptns, ptn)
  end
  return ptns
end

local function insert_or_update(fetchUrl)
  local existing = db.entries:where { url = fetchUrl }
  if existing == nil then
    db.entries:insert { url = fetchUrl }
  else
    local ts = os.time(os.date("!*t"))
    db.entries:update {
      where = { id = existing.id },
      set = { last_used = ts }
    }
  end
end

local function fetch_and_display(fetchUrl, opts)
  opts = opts or {}

  insert_or_update(fetchUrl)
  print("Fetching " .. fetchUrl)

  local curl = require"plenary.curl"
  local res = curl.get(fetchUrl)

  -- if res.status ~= 200 then
  --   error("Status was not 200 - " .. res.status)
  --   return
  -- end

  local body_lines = split_lines(res.body)

  vim.api.nvim_command('botright vnew')

  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_name(buf, 'fetched ' .. fetchUrl)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  if ends_with(fetchUrl, '.xml') then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'xml')
  end

  if ends_with(fetchUrl, '.json') then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
  end

  vim.api.nvim_put(body_lines, "", true, false)
end

local function map(maptbl, f)
  local t = {}
  for k, v in pairs(maptbl) do
    t[k] = f(v)
  end
  return t
end

sapi.endpoint_with_urn = function(opts)
  local node = ts_utils.get_node_at_cursor()
  if node == nil then
    error("No Treesitter parser found.")
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local txt = vim.treesitter.query.get_node_text(node, bufnr)
  txt = txt:gsub('"','')

  if string.find(txt, "^sr:(%a+):%d+$") == nil then
    print("Not a valid SR URN: " .. txt)
  else
    print("Valid SR URN: " .. txt)
  end

  local urn_types = {}
  for k, r in pairs(endpoints.requirements) do
    r = r:gsub('\\d', '%%d')
    local ptns = split_regex(r)
    for _, p in pairs(ptns) do
      if string.find(txt, p) ~= nil and string.find(k, "^_") == nil then
        table.insert(urn_types, "{" .. k .. "}")
      end
    end
  end
  print(vim.inspect(urn_types))

  local urn_endpoints = {}
  for _, v in pairs(endpoints.examples) do
    local found = false
    for _, ptn in pairs(urn_types) do
      print("looking for " .. ptn .. " in " .. v)
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
          utils.__warn_no_selection "builtin.builtin"
          return
        end

        fetch_and_display(sapi_config.base_url .. selection[1], {})
      end)
      return true
    end
  }):find()
end

sapi.recents = function(opts)
  opts = opts or {}
  local entries = db.entries:get()
  table.sort(entries, function (k1, k2)
    return k1.last_used > k2.last_used
  end)
  local urls = map(entries, function(entry)
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
          utils.__warn_no_selection "builtin.builtin"
          return
        end

        fetch_and_display(selection[1], {})
      end)
      return true
    end
  }):find()
end

sapi.update_endpoints = function(opts)
  opts = opts or {}

  local routes_url = sapi_config.base_url .. "/" .. sapi_config.package .. "/routes.json"
  local endpoints_json = utils.get_os_command_output(
    { "curl", "-s", routes_url },
    opts.cwd
  )

  endpoints = vim.fn.json_decode(endpoints_json)
  endpoints.examples = {}

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

sapi.endpoints = function(opts)
  opts = opts or {}

  sapi.update_endpoints(opts)

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
          utils.__warn_no_selection "builtin.builtin"
          return
        end
        local fetchUrl = sapi_config.base_url .. selection[1]
        for idPlaceHolder in string.gmatch(fetchUrl, '{(%a+)}') do
          vim.ui.input({
            prompt = idPlaceHolder .. ": ",
          }, function(idInput)
            fetchUrl = string.gsub(fetchUrl, "{" .. idPlaceHolder .. "}", idInput)
          end)
        end

        fetch_and_display(fetchUrl)
      end)

      return true
    end
  }):find()
end

return sapi


