vim.api.nvim_create_user_command("ApiBrowserRecents", require("api-browser").recents, {})
vim.api.nvim_create_user_command("ApiBrowserEndpoints", require("api-browser").endpoints, {})
vim.api.nvim_create_user_command("ApiBrowserAPI", require("api-browser").select_api, {})
vim.api.nvim_create_user_command("ApiBrowserSelectEnv", require("api-browser").select_server, {})
vim.api.nvim_create_user_command("ApiBrowserSelectRemoteEnv", require("api-browser").select_remote_server, {})
vim.api.nvim_create_user_command("ApiBrowserGoto", require("api-browser").endpoint_with_urn, {})
-- vim.api.nvim_create_user_command("ApiBrowserRefresh", require("api-browser").refresh_endpoints, {})

