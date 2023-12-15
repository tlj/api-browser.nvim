local stub = require('luassert.stub')
local db = require('api-browser.db')

describe("api-browser.config", function()
  db.dbdir = "/tmp/"
  db.dbfile = "test.db"

  before_each(function()
    db.remove()
  end)

  after_each(function()
    db.remove()
  end)

  describe("takes base_url from env and config", function()
    local module = require("api-browser.config")

    before_each(function()
      stub(os, "getenv")
    end)

    after_each(function ()
      os.getenv:revert()
    end)

    it("remembers env", function()
      module.setup()
      assert.is.equal("", module.get_selected_server())
      assert.is.equal("", module.get_selected_remote_server())
      module.set_selected_server("nonprod")
      module.set_selected_remote_server("prod")
      assert.is.equal("nonprod", module.get_selected_server())
      assert.is.equal("prod", module.get_selected_remote_server())
      module.options.selected_server = "dev"
      module.options.selected_remote_server = "review"
      module.setup()
      assert.is.equal("nonprod", module.get_selected_server())
      assert.is.equal("prod", module.get_selected_remote_server())
    end)

    it("remembers env by workspace", function()
      module.setup({workspace="test_ws_1"})
      assert.is.equal("", module.get_selected_server())
      module.set_selected_server("ws_1_server")

      module.setup({workspace="test_ws_2"})
      assert.is.equal("", module.get_selected_server())
      module.set_selected_server("ws_2_server")

      module.setup({workspace="test_ws_1"})
      assert.is.equal("ws_1_server", module.get_selected_server())
      module.setup({workspace="test_ws_2"})
      assert.is.equal("ws_2_server", module.get_selected_server())
    end)
  end)
end)
