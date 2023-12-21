local conf = require("api-browser.config")
local openapi = require("api-browser.openapi")

local M = {}

M.select_local_server = function(opts)
	opts = opts or {}

	openapi.parse_file(conf.get_selected_api())

	require("telescope.pickers")
		.new(opts, {
			prompt_title = "Select the local server",
			finder = require("telescope.finders").new_table({
				results = openapi.get_servers(),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name .. " (" .. entry.url .. ")",
						ordinal = entry.name .. " (" .. entry.url .. ")",
					}
				end,
			}),
			sorter = require("telescope.config").values.generic_sorter(opts),
			attach_mappings = function(fbuf)
				require("telescope.actions").select_default:replace(function()
					require("telescope.actions").close(fbuf)
					local selection = require("telescope.actions.state").get_selected_entry()
					if not selection then
						require("telescope.utils").__warn_no_selection("builtin.builtin")
						return
					end

					conf.set_selected_server(selection.value.name)
				end)
				return true
			end,
		})
		:find()
end

return M
