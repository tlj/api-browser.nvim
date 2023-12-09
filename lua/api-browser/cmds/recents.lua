local db = require("api-browser.db")
local utils = require("api-browser.utils")
local actions = require("api-browser.actions")

local M = {}

M.recents = function(opts)
  opts = opts or {}
  local entries = db.get_entries()
  table.sort(entries, function (k1, k2)
    return k1.last_used > k2.last_used
  end)
  local urls = utils.map(entries, function(entry)
    -- return { url = row.url, last_used = row.last_used }
    return vim.fn.json_decode(entry.endpoint)
  end)
  require("telescope.pickers").new(opts, {
    prompt_title = "",
    finder = require("telescope.finders").new_table {
      results = urls,
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
