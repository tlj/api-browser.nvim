local stub = require('luassert.stub')
local db = require('endpoint-previewer.db')

describe("endpoint-preview.config", function()
  db.dbdir = "/tmp/"
  db.dbfile = "test.db"
  vim.fn.setenv("ENDPOINT_PREVIEWER_URLS", "")

  before_each(function()
    db.remove()
  end)

  after_each(function()
    db.remove()
  end)

  describe("has a dev and prod base url", function()
    local module = require("endpoint-previewer.config")
    it("has dev url", function()
      module.setup({
        env_base_urls = {
          dev = "https://localhost",
        },
        selected_env = 'dev'
      })

      assert.is_same({dev = "https://localhost"}, module.options.env_base_urls)
      assert.equals("https://localhost", module.selected_base_url())
      assert.is_nil(module.selected_remote_base_url())
    end)
  end)

  describe("takes base_url from env and config", function()
    local module = require("endpoint-previewer.config")

    before_each(function()
      stub(os, "getenv")
    end)

    after_each(function ()
      os.getenv:revert()
    end)

    it("gets staging env from os env", function()
      os.getenv.on_call_with("ENDPOINT_PREVIEWER_URLS").returns("staging=https://staging")
      module.setup({env_base_urls={}, selected_env='dev'})
      assert.is_same({staging = "https://staging"}, module.options.env_base_urls)
    end)

    it("returns a full endpoint url", function()
      module.setup({env_base_urls={dev="https://localhost",nonprod="https://nonprod"}})
      module.set_selected_env("nonprod")
      assert.equals("https://nonprod/endpoints.json", module.endpoints_url())
    end)

    it("returns a full endpoint url, with custom endpoints path", function()
      module.setup({env_base_urls={dev="https://localhost",nonprod="https://nonprod"}, endpoints_url_path = "/endpoints/routes.json" })
      module.set_selected_env("nonprod")
      assert.equals("https://nonprod/endpoints/routes.json", module.endpoints_url())
    end)

    it("returns a full endpoint url, with custom endpoints path, without selecting env", function()
      module.setup({env_base_urls={dev="https://localhost",nonprod="https://nonprod"}, endpoints_url_path = "/endpoints/routes.json", env = "nonprod" })
      assert.equals("https://nonprod/endpoints/routes.json", module.endpoints_url())
    end)

    it("merges base_url env from options and env", function()
      os.getenv.on_call_with("ENDPOINT_PREVIEWER_URLS").returns("staging=https://staging")
      module.setup({env_base_urls={dev="https://localhost"}, selected_env='dev'})
      assert.is_same({dev = "https://localhost", staging = "https://staging"}, module.options.env_base_urls)
      local envs = module.get_environments()
      table.sort(envs, function(a, b)
        return a.name < b.name
      end)
      assert.same({{name = "dev", url = "https://localhost"}, {name = "staging", url = "https://staging"}}, envs)
    end)

    it("remembers env", function()
      module.setup()
      assert.equals("dev", module.get_selected_env())
      assert.equals("prod", module.get_selected_remote_env())
      module.set_selected_env("nonprod")
      module.set_selected_remote_env("remoteenv")
      assert.equals("nonprod", module.get_selected_env())
      assert.equals("remoteenv", module.get_selected_remote_env())
      module.options.selected_env = "dev"
      module.options.selected_remote_env = "prod"
      module.setup()
      assert.equals("nonprod", module.get_selected_env())
      assert.equals("remoteenv", module.get_selected_remote_env())
    end)
  end)
end)
