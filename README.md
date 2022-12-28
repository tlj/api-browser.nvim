# SAPI Preview for Neovim

A [Neovim](https://neovim.io/) plugin to browse SAPI feeds directly in the browser.

## Features

- Uses remote routes.json file to get all data
- Cache packages and endpoints in sqlite database for faster lookups
- Quickly access recent URLs 
- Switch between backend base URLs 
- Package selector to quickly switch between packages 
- Select from URLs which match the URN under the cursor 

## Requirements

- [sqlite.lua](https://github.com/kkharji/sqlite.lua) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required)
- [jq](https://stedolan.github.io/jq/) (required)
- [xmllint](https://gnomes.pages.gitlab.gnome.org/libxml2/xmllint.html) (required)
- [curl](https://curl.se) (required)

## Installation

### [Packer.nvim](https://github.com/wbthomason/packer.nvim) 

```lua
use {
  "tlj/sapi-preview.nvim",
  {
    "kkharji/sqlite.lua",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  }
}
```

An environment variable is required to set the base urls, as they should be left out of repositories commited to github.

```bash
$ export SAPI_PREVIEW_URLS="https://url1.example;https://url2.example"
```

## Usage

Select a base url from the list defined in SAPI_PREVIEW_URLS. This will be used in subsequent lookups.
```vim
:lua require'sapi-preview'.select_base_url()
```

Select a package to use when using the endpoints selector.
```vim
:lua require'sapi-preview'.select_package()
```

Select from a list of endpoints valid for the package. If an endpoint has a placeholder, the user will be prompted to enter a value.
```vim
:lua require'sapi-preview'.endpoints()
```

Look up current package endpoints with a placeholder with requirements matching the text the cursor is currently on.
```vim
:lua require'sapi-preview'.endpoint_with_urn()
```

### Suggested mappings

```vim
require('sapi-preview').setup()
vim.keymap.set('n', '<leader>sg', '<cmd>lua require"sapi-preview".endpoint_with_urn()<cr>', {})
vim.keymap.set('n', '<leader>sr', '<cmd>lua require"sapi-preview".recents()<cr>', {})
vim.keymap.set('n', '<leader>se', '<cmd>lua require"sapi-preview".endpoints()<cr>', {})
vim.keymap.set('n', '<leader>su', '<cmd>lua require"sapi-preview".refresh_endpoints()<cr>', {})
vim.keymap.set('n', '<leader>sp', '<cmd>lua require"sapi-preview".select_package()<cr>', {})
vim.keymap.set('n', '<leader>sb', '<cmd>lua require"sapi-preview".select_base_url()<cr>', {})
```

### Database location

The default location for the sqlite3 database is `$XDG_DATA_HOME/nvim' (eq '~/.local/share/nvim/databases' on linux and MacOS).



