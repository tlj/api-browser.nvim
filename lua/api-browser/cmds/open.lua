local conf = require("api-browser.config")
local actions = require("api-browser.actions")
local db = require("api-browser.db")
local openapi = require("api-browser.openapi")

local M = {}

M.open = function(opts)
  opts = opts or {}

  local openapis = openapi.get_apis()

  require("telescope.pickers").new(opts, {
    prompt_title = "Select an API",
    finder = require("telescope.finders").new_table {
      results = openapis,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
        }
      end,
    },
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(fbuf, map)
      require("telescope.actions").select_default:replace(function()
        require("telescope.actions").close(fbuf)
        local selection = require("telescope.actions.state").get_selected_entry()
        if not selection then
          require("telescope.utils").__warn_no_selection "builtin.builtin"
          return
        end

        conf.set_selected_api(selection.value.name)
        db.set_default(conf.workspace, "api", conf.get_selected_api())
      end)

      map('n', 't', actions.telescope_test_api)

      return true
    end
  }):find()
end


return M
