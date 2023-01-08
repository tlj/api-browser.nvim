set rtp+=.
set rtp+=vendor/plenary.nvim
set rtp+=vendor/sqlite.lua

runtime! plugin/plenary.vim
runtime! plugin/sqlite.lua

lua require'plenary.busted'
lua require'sqlite'
