local db = require("sapi-preview.db")
local conf = require("sapi-preview.config")
local utils = require("sapi-preview.utils")
local fetch = require("sapi-preview.fetch")

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
