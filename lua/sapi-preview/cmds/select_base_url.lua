local conf = require("sapi-preview.config")
local db = require("sapi-preview.db")

local M = {}

M.select_base_url = function(opts)
  opts = opts or {}

  require("telescope.pickers").new(opts, {
    prompt_title = "Select a base URL",
    finder = require("telescope.finders").new_table {
      results = conf.options.base_urls,
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

        require("sapi-preview.config").options.base_url = selection[1]
        db.set_default("base_url", require("sapi-preview.config").options.base_url)
      end)
      return true
    end
  }):find()
end


return M
