local conf = require("endpoint-previewer.config")
local db = require("endpoint-previewer.db")

local M = {}

local function update_packages()
  local packages = db.get_packages()
  if next(packages) == nil then
    M.refresh_packages()
    packages = db.get_packages()
  end
  require("endpoint-previewer.config").set_packages(packages)
end

M.select_api = function(opts)
  opts = opts or {}

  if next(conf.packages) == nil then
    update_packages()
  end

  require("telescope.pickers").new(opts, {
    prompt_title = "Select a package (" .. require("endpoint-previewer.config").options.base_url .. ")",
    finder = require("telescope.finders").new_table {
      results = conf.packages,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name .. " " .. entry.version,
          ordinal = entry.name .. " " .. entry.version,
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

        conf.set_endpoints({})

        print("Setting package " .. selection.value.name .. " " .. selection.value.version)
        conf.set_package(selection.value.name .. "/" .. selection.value.version .. "/en")
        db.set_default("package", conf.options.package)
      end)
      return true
    end
  }):find()
end


return M
