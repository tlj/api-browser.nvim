-- vim.api.nvim_create_user_command("ApiBrowserRecents", require("api-browser").recents, {})
-- vim.api.nvim_create_user_command("ApiBrowserEndpoints", require("api-browser").endpoints, {})
-- vim.api.nvim_create_user_command("ApiBrowserOpen", require("api-browser").select_api, {})
-- vim.api.nvim_create_user_command("ApiBrowserSelectLocalServer", require("api-browser").select_server, {})
-- vim.api.nvim_create_user_command("ApiBrowserSelectRemoteServer", require("api-browser").select_remote_server, {})
-- vim.api.nvim_create_user_command("ApiBrowserGoto", require("api-browser").endpoint_with_urn, {})
-- vim.api.nvim_create_user_command("ApiBrowserRefresh", require("api-browser").refresh_endpoints, {})

vim.api.nvim_create_user_command("ApiBrowser", function(opts)
	require("api-browser.cmd").load_command(unpack(opts.fargs))
end, {
	nargs = 1,
	complete = function(_, _, _)
		return {
			"open",
			"select_local_server",
			"select_remote_server",
			"recents",
			"endpoints",
			"endpoints_with_param",
			-- "refresh_endpoints",
		}
	end,
})
