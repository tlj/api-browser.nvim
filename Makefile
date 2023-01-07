.PHONY: prepare test

clean:
	rm -rf vendor/*

prepare: 
	@luarocks install luacheck --local

vendor: clean
	@git clone https://github.com/nvim-lua/plenary.nvim vendor/plenary.nvim
	@git clone https://github.com/kkharji/sqlite.lua vendor/sqlite.lua

test:
	@nvim --headless --clean -u test/minimal_vim.vim -c "PlenaryBustedDirectory test/spec/endpoint-previewer {minimal_init = './test/minimal_vim.vim'}" +q



