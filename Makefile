.PHONY: prepare test

clean:
	rm -rf vendor/*

prepare: 
	@luarocks install luacheck --local
	@sudo npm i -g open-api-mocker

vendor: clean
	@git clone https://github.com/nvim-lua/plenary.nvim vendor/plenary.nvim
	@git clone https://github.com/kkharji/sqlite.lua vendor/sqlite.lua

test:
	@nvim --headless --clean -u test/minimal_vim.vim -c "lua require('plenary.test_harness').test_directory('test/spec/api-browser', {minimal_init = './test/minimal_vim.vim', sequential = true})" +q

mock-dev:
	@open-api-mocker -s test/fixtures/petstore.json -w -p 5000

mock-remote:
	@open-api-mocker -s test/fixtures/petstore.json -w -p 5500


