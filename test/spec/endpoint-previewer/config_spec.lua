local stub = require('luassert.stub')
local db = require('endpoint-previewer.db')

describe("endpoint-preview.config", function()
  before_each(function()
    db.set_default = function(_, _) end
    db.get_default = function(_) return nil end
    db.init = function() return nil end
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
  end)
end)
