local db = require("api-browser.db")

local M = {
	workspace = "",
	defaults = {
		options = {
			keep_state = true,
			ripgrep = {
				command = "rg -l -g '*.yaml' -g '*.json' -e \"openapi.*3\"",
				no_ignore = false,
				fallback_globs = { "**/*.yaml", "**/*.json" },
			},
			curl = {
				command = "curl",
				formatters = {
					["application/json"] = { "jq", "." },
					["application/xml"] = { "xmllint", "-format" },
				},
			},
		},
		state = {
			selected_api = "",
			selected_server = "",
			selected_remote_server = "",
		},
	},
	options = {},
	state = {},
}

M.set_selected_api = function(api)
	M.state.selected_api = api
	db.set_default(M.workspace, "selected_api", api)
end

M.get_selected_api = function()
	return M.state.selected_api
end

M.set_selected_server = function(server)
	M.state.selected_server = server
	db.set_default(M.workspace, "selected_server", server)
end

M.get_selected_server = function()
	return M.state.selected_server
end

M.set_selected_remote_server = function(server)
	M.state.selected_remote_server = server
	db.set_default(M.workspace, "selected_remote_server", server)
end

M.get_selected_remote_server = function()
	return M.state.selected_remote_server
end

M.setup = function(opts)
	opts = opts or {}

	M.workspace = opts.workspace or vim.fn.getcwd()
	M.state = vim.deepcopy(M.defaults.state)

	local options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults.options), opts or {})

	if options.keep_state then
		for k, _ in pairs(M.state) do
			local v = db.get_default(M.workspace, k)
			if v ~= nil then
				M.state[k] = v
			end
		end
	end

	M.options = options
end

return M
