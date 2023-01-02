local db = require("sapi-preview.db")
local fetch = require("sapi-preview.fetch")
local conf = require("sapi-preview.config")

local M = {}

M.endpoints = function(opts)
  opts = opts or {}

  if conf.endpoints.examples == nil then
    print("No examples, updating endpoints")
    require("sapi-preview.cmds.update_endpoints").update_endpoints(opts)
  end

  require("telescope.pickers").new(opts, {
    prompt_title = "Endpoints (" .. conf.options.base_url .. ")",
    finder = require("telescope.finders").new_table {
      results = conf.endpoints.examples,
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

        local fetchUrl = conf.options.base_url .. selection[1]
        for idPlaceHolder in string.gmatch(fetchUrl, '{(%a+)}') do
          vim.ui.input({
            prompt = idPlaceHolder .. ": ",
          }, function(idInput)
            fetchUrl = string.gsub(fetchUrl, "{" .. idPlaceHolder .. "}", idInput)
          end)
        end

        db.push_history(selection[1])

        vim.api.nvim_command('botright vnew')
        local buf = vim.api.nvim_get_current_buf()
        vim.schedule(function()
          fetch.fetch_and_display(fetchUrl, {buf = buf})
        end)
      end)

      return true
    end
  }):find()
end


return M
