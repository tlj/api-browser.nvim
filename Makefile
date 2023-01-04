.PHONY: prepare test

clean:
	rm -rf vendor/plenary.nvim

prepare: clean
	@git clone https://github.com/nvim-lua/plenary.nvim vendor/plenary.nvim
	@luarocks install luacheck --local

test:
	nvim --headless -c "PlenaryBustedDirectory test/spec/endpoint-previewer {minimal_init = './test/minimal_vim.vim'}"


