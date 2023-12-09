local actions = require("api-browser.actions")
local conf = require("api-browser.config")
local openapi = require("api-browser.openapi")

local M = {}

M.endpoints = function(opts)
  opts = opts or {}

  openapi.parse_file(conf.get_selected_api())
  local parsed_urls = openapi.parse_endpoints()
  if not parsed_urls then
    parsed_urls = {}
  end

  require("telescope.pickers").new(opts, {
    prompt_title = "Endpoints (" .. conf.get_selected_server() .. ")",
    finder = require("telescope.finders").new_table {
      results = parsed_urls,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display_name,
          ordinal = entry.display_name,
        }
      end,
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
