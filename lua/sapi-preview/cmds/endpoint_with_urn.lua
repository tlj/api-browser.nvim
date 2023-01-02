local db = require("sapi-preview.db")
local fetch = require("sapi-preview.fetch")
local conf = require("sapi-preview.config")
local utils = require("sapi-preview.utils")

local M = {}

M.endpoint_with_urn = function(opts)
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
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

  if conf.endpoints.requirements == nil or conf.endpoints.examples == nil then
    require("sapi-preview.cmds.update_endpoints").update_endpoints({})
  end

  local urn_types = {}
  for k, r in pairs(conf.endpoints.requirements) do
    r = r:gsub('\\d', '%%d')
    local ptns = utils.split_regex(r)
    for _, p in pairs(ptns) do
      if string.find(txt, p) ~= nil and string.find(k, "^_") == nil then
        table.insert(urn_types, "{" .. k .. "}")
      end
    end
  end

  local urn_endpoints = {}
  for _, v in pairs(conf.endpoints.examples) do
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
  require("telescope.pickers").new(opts, {
    prompt_title = "Endpoints for urn " .. txt .. " (" .. require("sapi-preview.config").options.base_url .. ")",
    finder = require("telescope.finders").new_table {
      results = urn_endpoints,
    },
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(fbuf, attmap)
      require("telescope.actions").select_default:replace(function()
        require("telescope.actions").close(fbuf)
        local selection = require("telescope.actions.state").get_selected_entry()
        if not selection then
          require("telescope.utils").__warn_no_selection "builtin.builtin"
          return
        end

        db.push_history(selection[1])

        vim.api.nvim_command('botright vnew')
        local buf = vim.api.nvim_get_current_buf()
        vim.schedule(function()
          fetch.fetch_and_display(conf.options.base_url .. selection[1], {buf = buf})
        end)
      end)
      return true
    end
  }):find()
end

return M

