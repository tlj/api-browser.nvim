local db = require("endpoint-previewer.db")
local utils = require("endpoint-previewer.utils")
local actions = require("endpoint-previewer.actions")

local M = {}

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
  require("telescope.pickers").new(opts, {
    prompt_title = "",
    finder = require("telescope.finders").new_table {
      results = urls,
    },
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(buf, map)
      require("telescope.actions").select_default:replace(actions.telescope_select)
      map('n', 'c', actions.telescope_compare_endpoint)

      return true
    end
  }):find()
end

return M
