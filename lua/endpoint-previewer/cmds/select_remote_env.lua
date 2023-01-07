local conf = require("endpoint-previewer.config")

local M = {}

M.select_remote_env = function(opts)
  opts = opts or {}

  require("telescope.pickers").new(opts, {
    prompt_title = "Select a remote environment",
    finder = require("telescope.finders").new_table {
      results = conf.get_environments(),
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name .. " (" .. entry.url .. ")",
          ordinal = entry.name .. " (" .. entry.url .. ")",
        }
      end,
    },
    sorter = require("telescope.config").values.generic_sorter(opts),
    attach_mappings = function(fbuf)
      require("telescope.actions").select_default:replace(function()
        require("telescope.actions").close(fbuf)
        local selection = require("telescope.actions.state").get_selected_entry()
        if not selection then
          require("telescope.utils").__warn_no_selection "builtin.builtin"
          return
        end

        conf.set_selected_remote_env(selection.value.name)
      end)
      return true
    end
  }):find()
end

return M

