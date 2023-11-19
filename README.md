# API Browser for Neovim

[![tests](https://github.com/tlj/api-browser.nvim/actions/workflows/integration.yml/badge.svg)](https://github.com/tlj/api-browser.nvim/actions/workflows/integration.yml)

A [Neovim](https://neovim.io/) plugin to browse API endpoints directly in the
editor.

## Features

- Loads any openapi.yaml/json files which are in the project
- Cache recent endpoints, APIs and base url options in sqlite database for
  persistency
- Quickly access recent URLs 
- Switch between the servers defined in the selected OpenAPI spec
- API selector to quickly switch between OpenAPIs available in the workspace
- Select from endpoints which match the replacement requirements under the
  cursor 
- Load endpoint from 2 selected servers in separate windows with scoll lock, for
  easy comparison
- Load endpoint in diff view between server 1 and 2
- Debug mode; Opens DAP UI and starts debugging mode on opening an endpoint

## Getting started

Use `:checkhealth api-browser` to verify that all required plugins and
binaries are installed correctly.

### Required plugins

- [sqlite.lua](https://github.com/kkharji/sqlite.lua) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) (optional, for debug mode)
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) (optional, for debug mode)

### Required binaries

- [neovim](https://neovim.io) (required)
- [jq](https://stedolan.github.io/jq/) (required)
- [xmllint](https://gnomes.pages.gitlab.gnome.org/libxml2/xmllint.html)
  (required)
- [curl](https://curl.se) (required)
- [yq](https://github.com/mikefarah/yq) (required)

### Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim) 

```lua 
use { 
	"tlj/api-browser.nvim", 
	{ 
		"kkharji/sqlite.lua",
		"nvim-lua/plenary.nvim", 
		"nvim-telescope/telescope.nvim", 
	} 
} 
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua 
{ 
	"tlj/api-browser.nvim", 
	dependencies = { 
		"kkharji/sqlite.lua",
    "nvim-lua/plenary.nvim", 
    "nvim-telescope/telescope.nvim", 
	}, 
	config = function() require("api-browser").setup() end, 
	keys = { 
		{ "<leader>sg", "<cmd>ApiBrowserGoto<cr>", desc = "Open API endpoints valid for replacement text on cursor." },
		{ "<leader>sr", "<cmd>ApiBrowserRecents<cr>", desc = "Open list of recently opened API endpoints." },
		{ "<leader>se", "<cmd>ApiBrowserEndpoints<cr>", desc = "Open list of endpoints for current API." },
		{ "<leader>su", "<cmd>ApiBrowserRefresh<cr>", desc = "Refresh list of APIs and Endpoints." },
		{ "<leader>sa", "<cmd>ApiBrowserAPI<cr>", desc = "Select an API." },
    { "<leader>sd", "<cmd>ApiBrowserSelectEnv<cr>", desc = "Select environment." },
    { "<leader>sx", "<cmd>ApiBrowserSelectRemoteEnv<cr>", desc = "Select remote environment." },
	}, 
} 
```

### checkhealth

Make sure you call `:checkhealth api-browser` after installing the plugin
to ensure that everything is set up correctly.

## Usage

Use `q` to close endpoint previews from normal mode.

### Pickers

To enter normal mode in the telescope selector, use `<esc>` after selecting
the endpoint you want to work on.

Use `c` in normal mode in any telescope selector for endpoints to open the
endpoint in two windows (selected remote env and selected dev env) for comparison.

Use `d` to open a similar view to `c`, but with diff mode enabled, showing the
differences between the endpoints. The differences can be navigated by using
`[c` and `]c`.

Use `b` to open debug mode. This requires `dap` and `dapui` installed - use 
`:checkhealth api-browser` to verify. Debug mode opens DAP UI and starts 
DAP, then triggers loading the endpoint from the selected base url. When the 
endpoint has finished loading the debugger will stop and the UI will close 
automatically.

### Vim Commands

```vim 
" Select the environment which should be used by default, and as the 
" target environment for diff view
:ApiBrowserSelectEnv

" Select the environment which should be used as the source environment
" for the diff view
:ApiBrowserSelectRemoteEnv

" Select an API to use when using the endpoints selector. 
:ApiBrowserAPI 

" Select from a list of endpoints valid for the API. If an endpoint 
" has a placeholder, the user will be prompted to enter a value. 
:ApiBrowserEndpoints 

" Select from a list of recently used endpoints. The endpoint is 
" not remembered by base url, so it can be used to quickly open 
" the same endpoint across different base urls. 
:ApiBrowserRecents 

" Look up current API endpoints with a placeholder with requirements 
" matching the text the cursor is currently on. 
:ApiBrowserGoto 

" Refresh the list of endpoints from the server (clear cache). 
:ApiBrowserRefresh 
```

### Suggested mappings

```vim 
require('api-browser').setup() 
vim.keymap.set('n', '<leader>sg', '<cmd>ApiBrowserGoto<cr>', {}) 
vim.keymap.set('n', '<leader>sr', '<cmd>ApiBrowserRecents<cr>', {}) 
vim.keymap.set('n', '<leader>se', '<cmd>ApiBrowserEndpoints<cr>', {}) 
vim.keymap.set('n', '<leader>su', '<cmd>ApiBrowserRefresh<cr>', {}) 
vim.keymap.set('n', '<leader>sa', '<cmd>ApiBrowserAPI<cr>', {}) 
vim.keymap.set('n', '<leader>sd', '<cmd>ApiBrowserSelectEnv<cr>', {})
vim.keymap.set('n', '<leader>sx', '<cmd>ApiBrowserSelectRemoteEnv<cr>', {})
```

### Database location

The default location for the sqlite3 database is `$XDG_DATA_HOME/nvim` (eq
`~/.local/share/nvim/databases` on linux and MacOS).



