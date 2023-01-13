# Endpoint Previewer for Neovim

[![tests](https://github.com/tlj/endpoint-previewer.nvim/actions/workflows/integration.yml/badge.svg)](https://github.com/tlj/endpoint-previewer.nvim/actions/workflows/integration.yml)

A [Neovim](https://neovim.io/) plugin to browse API endpoints directly in the
editor.

## Features

- Uses remote [endpoints.json](ENDPOINTS.md) file to get a list of all APIs and endpoints
- Cache recent endpoints, APIs and base url options in sqlite database for
  persistency
- Quickly access recent URLs 
- Switch between backend base URLs 
- API selector to quickly switch between APIs 
- Select from endpoints which match the replacement requirements under the
  cursor 
- Load endpoint from 2 first base urls in separate windows with scoll lock, for
  easy comparison
- Load endpoint in diff view between base url 1 and 2
- Debug mode; Opens DAP UI and starts debugging mode on opening an endpoint

## Getting started

Use `:checkhealth endpoint-previewer` to verify that all required plugins and
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

### Installation

An environment variable is required to set the base urls, as they should be left
out of repositories commited to github.

```bash 
$ export ENDPOINT_PREVIEWER_URLS="https://url1.example;https://url2.example" 
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim) 

```lua 
use { 
	"tlj/endpoint-previewer.nvim", 
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
	"tlj/endpoint-previewer.nvim", 
	dependencies = { 
		"kkharji/sqlite.lua",
        "nvim-lua/plenary.nvim", 
        "nvim-telescope/telescope.nvim", 
	}, 
	config = function() require("endpoint-previewer").setup() end, 
	keys = { 
		{ "<leader>sg", "<cmd>EndpointGoto<cr>", desc = "Open API endpoints valid for replacement text on cursor." },
		{ "<leader>sr", "<cmd>EndpointRecents<cr>", desc = "Open list of recently opened API endpoints." },
		{ "<leader>se", "<cmd>EndpointEndpoints<cr>", desc = "Open list of endpoints for current API." },
		{ "<leader>su", "<cmd>EndpointRefresh<cr>", desc = "Refresh list of APIs and Endpoints." },
		{ "<leader>sa", "<cmd>EndpointAPI<cr>", desc = "Select an API." },
    { "<leader>sd", "<cmd>EndpointSelectEnv<cr>", desc = "Select environment." },
    { "<leader>sx", "<cmd>EndpointSelectRemoteEnv<cr>", desc = "Select remote environment." },
	}, 
} 
```

### checkhealth

Make sure you call `:checkhealth endpoint-previewer` after installing the plugin
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
`:checkhealth endpoint-previewer` to verify. Debug mode opens DAP UI and starts 
DAP, then triggers loading the endpoint from the selected base url. When the 
endpoint has finished loading the debugger will stop and the UI will close 
automatically.

### Vim Commands

```vim 
" Select the environment which should be used by default, and as the 
" target environment for diff view
:EndpointSelectEnv

" Select the environment which should be used as the source environment
" for the diff view
:EndpointSelectRemoteEnv

" Select an API to use when using the endpoints selector. 
:EndpointAPI 

" Select from a list of endpoints valid for the API. If an endpoint 
" has a placeholder, the user will be prompted to enter a value. 
:EndpointEndpoints 

" Select from a list of recently used endpoints. The endpoint is 
" not remembered by base url, so it can be used to quickly open 
" the same endpoint across different base urls. 
:EndpointRecents 

" Look up current API endpoints with a placeholder with requirements 
" matching the text the cursor is currently on. 
:EndpointGoto 

" Refresh the list of endpoints from the server (clear cache). 
:EndpointRefresh 
```

### Suggested mappings

```vim 
require('endpoint-previewer').setup() 
vim.keymap.set('n', '<leader>sg', '<cmd>EndpointGoto<cr>', {}) 
vim.keymap.set('n', '<leader>sr', '<cmd>EndpointRecents<cr>', {}) 
vim.keymap.set('n', '<leader>se', '<cmd>EndpointEndpoints<cr>', {}) 
vim.keymap.set('n', '<leader>su', '<cmd>EndpointRefresh<cr>', {}) 
vim.keymap.set('n', '<leader>sa', '<cmd>EndpointAPI<cr>', {}) 
vim.keymap.set('n', '<leader>sd', '<cmd>EndpointSelectEnv<cr>', {})
vim.keymap.set('n', '<leader>sx', '<cmd>EndpointSelectRemoteEnv<cr>', {})
```

### Database location

The default location for the sqlite3 database is `$XDG_DATA_HOME/nvim` (eq
`~/.local/share/nvim/databases` on linux and MacOS).



