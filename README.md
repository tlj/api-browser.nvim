# Endpoint Previewer for Neovim

A [Neovim](https://neovim.io/) plugin to browse API endpoints directly in the editor.

## Features

- Uses remote endpoints.json file to get a list of all APIs and endpoints
- Cache APIs and endpoints in sqlite database for faster lookups
- Quickly access recent URLs 
- Switch between backend base URLs 
- API selector to quickly switch between APIs 
- Select from endpoints which match the replacement requirements under the cursor 
- Load endpoint from 2 first base urls in separate windows with scoll lock, for easy comparison

## Getting started

### Required plugins

- [sqlite.lua](https://github.com/kkharji/sqlite.lua) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)

### Required binaries

- [neovim](https://neovim.io) (required)
- [jq](https://stedolan.github.io/jq/) (required)
- [xmllint](https://gnomes.pages.gitlab.gnome.org/libxml2/xmllint.html) (required)
- [curl](https://curl.se) (required)

### Installation

An environment variable is required to set the base urls, as they should be left out of repositories commited to github.

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
  },
  config = function()
    require("endpoint-previewer").setup()
  end,
  keys = {
    { "<leader>sg", "<cmd>EndpointGoto<cr>", desc = "Open API endpoints valid for replacement text on cursor." },
    { "<leader>sr", "<cmd>EndpointRecents<cr>", desc = "Open list of recently opened API endpoints." },
    { "<leader>se", "<cmd>EndpointEndpoints<cr>", desc = "Open list of endpoints for current API." },
    { "<leader>su", "<cmd>EndpointRefresh<cr>", desc = "Refresh list of APIs and Endpoints." },
    { "<leader>sp", "<cmd>EndpointAPI<cr>", desc = "Select an API." },
    { "<leader>sb", "<cmd>EndpointBaseUrl<cr>", desc = "Select a base URL to fetch endpoints from." },
  },
}
```

### checkhealth

Make sure you call `:checkhealth endpoint-previewer` after installing the plugin to ensure that everything is set up correctly.

## Usage

Use 'c' in normal mode in any telescope selector for endpoints to open the endpoint in two windows (base_url[1] and base_url[2]) for comparison.

Select a base url from the list defined in ENDPOINT_PREVIEWER_URLS. This will be used in subsequent lookups.
```vim
:EndpointBaseUrl
```

Select an API to use when using the endpoints selector.
```vim
:EndpointAPI
```

Select from a list of endpoints valid for the API. If an endpoint has a placeholder, the user will be prompted to enter a value.
```vim
:EndpointEndpoints
```

Select from a list of recently used endpoints. The endpoint is not remembered by base url, so it can be used to quickly open the same endpoint across different base urls.
```vim
:EndpointRecents
```

Look up current API endpoints with a placeholder with requirements matching the text the cursor is currently on.
```vim
:EndpointGoto
```

Refresh the list of endpoints from the server (clear cache).
```vim
:EndpointRefresh
```

### Suggested mappings

```vim
require('endpoint-previewer').setup()
vim.keymap.set('n', '<leader>sg', '<cmd>EndpointGoto<cr>', {})
vim.keymap.set('n', '<leader>sr', '<cmd>EndpointRecents<cr>', {})
vim.keymap.set('n', '<leader>se', '<cmd>EndpointEndpoints<cr>', {})
vim.keymap.set('n', '<leader>su', '<cmd>EndpointRefresh<cr>', {})
vim.keymap.set('n', '<leader>sp', '<cmd>EndpointAPI<cr>', {})
vim.keymap.set('n', '<leader>sb', '<cmd>EndpointBaseUrl<cr>', {})
```

### Database location

The default location for the sqlite3 database is `$XDG_DATA_HOME/nvim' (eq '~/.local/share/nvim/databases' on linux and MacOS).



