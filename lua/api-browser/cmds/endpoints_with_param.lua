local actions = require("api-browser.actions")
local conf = require("api-browser.config")
local endpoints = require("api-browser.openapi")

local M = {}

M.endpoints_with_param = function(opts)
  local node = require("nvim-treesitter.ts_utils").get_node_at_cursor()
  if node == nil then
    error("No Treesitter parser found.")
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local txt = vim.treesitter.get_node_text(node, bufnr)
  txt = txt:gsub('"','')

  local urn_endpoints = endpoints.get_endpoint_by_param_pattern(txt)

  require("telescope.pickers").new(opts, {
    prompt_title = "Endpoints for urn " .. txt .. " (" .. conf.get_selected_server() .. ")",
    finder = require("telescope.finders").new_table {
      results = urn_endpoints,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display_name,
          ordinal = entry.display_name,
        }
      end
    },
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(_, map)
      require("telescope.actions").select_default:replace(actions.telescope_select_endpoint)
      map('n', 'c', actions.telescope_compare_endpoint)
      map('n', 'd', actions.telescope_diff_endpoint)
      map('n', 'b', actions.telescope_debug_endpoint)
      map('n', 't', actions.telescope_test_endpoint)

      return true
    end
  }):find()
end

return M

