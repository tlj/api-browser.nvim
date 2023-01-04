local actions = require("endpoint-previewer.actions")
local conf = require("endpoint-previewer.config")
local endpoints = require("endpoint-previewer.endpoints")

local M = {}

M.endpoints = function(opts)
  opts = opts or {}

  local parsed_urls = endpoints.get_by_api_name(conf.options.package)
  if not parsed_urls then
    parsed_urls = {}
  end

  require("telescope.pickers").new(opts, {
    prompt_title = "Endpoints (" .. conf.options.base_url .. ")",
    finder = require("telescope.finders").new_table {
      results = parsed_urls,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.url,
          ordinal = entry.url,
        }
      end,
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
