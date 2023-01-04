local actions = require("endpoint-previewer.actions")
local conf = require("endpoint-previewer.config")
local endpoints = require("endpoint-previewer.endpoints")

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

  local urn_endpoints = endpoints.get_endpoint_by_api_name_and_urn(conf.options.package, txt)

  require("telescope.pickers").new(opts, {
    prompt_title = "Endpoints for urn " .. txt .. " (" .. conf.options.base_url .. ")",
    finder = require("telescope.finders").new_table {
      results = urn_endpoints,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.url,
          ordinal = entry.url,
        }
      end
    },
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(_, map)
      require("telescope.actions").select_default:replace(actions.telescope_select_endpoint)
      map('n', 'c', actions.telescope_compare_endpoint)

      return true
    end
  }):find()
end

return M

