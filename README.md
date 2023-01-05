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

## Getting started

### Required plugins

- [sqlite.lua](https://github.com/kkharji/sqlite.lua) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)

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
		{ "<leader>su", "<cmd>EndpointRefresh<cr>", desc = "Refresh list of APIs and
Endpoints." }, 
		{ "<leader>sp", "<cmd>EndpointAPI<cr>", desc = "Select an API." }, 
		{ "<leader>sb", "<cmd>EndpointBaseUrl<cr>", desc = "Select a base URL to
fetch endpoints from." }, 
	}, 
} 
```

### checkhealth

Make sure you call `:checkhealth endpoint-previewer` after installing the plugin
to ensure that everything is set up correctly.

## Usage

Use `c` in normal mode in any telescope selector for endpoints to open the
endpoint in two windows (`base_url[1]` and `base_url[2]`) for comparison.

Use `d` to open a similar view to `c`, but with diff mode enabled, showing the
differences between the endpoints. The differences can be navigated by using
`[c` and `]c`.

### Vim Commands

```vim 
" Select a base url from the list defined in ENDPOINT_PREVIEWER_URLS.
" This will be used in subsequent lookups. 
:EndpointBaseUrl 

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
vim.keymap.set('n', '<leader>sr', '<cmd>EndpointRecents<cr>', {}) vim.keymap.set('n', '<leader>se', '<cmd>EndpointEndpoints<cr>', {}) vim.keymap.set('n', '<leader>su', '<cmd>EndpointRefresh<cr>', {}) vim.keymap.set('n', '<leader>sp', '<cmd>EndpointAPI<cr>', {}) 
vim.keymap.set('n', '<leader>sb', '<cmd>EndpointBaseUrl<cr>', {}) 
```

### Database location

The default location for the sqlite3 database is `$XDG_DATA_HOME/nvim` (eq
`~/.local/share/nvim/databases` on linux and MacOS).


