.PHONY: prepare test

clean:
	rm -rf vendor/plenary.nvim

prepare: 
	@luarocks install luacheck --local

vendor: clean
	@git clone https://github.com/nvim-lua/plenary.nvim vendor/plenary.nvim

test:
	@nvim --headless -c "PlenaryBustedDirectory test/spec/endpoint-previewer {minimal_init = './test/minimal_vim.vim'}" +q


