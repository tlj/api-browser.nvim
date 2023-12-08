describe("api-browser.openapi", function()
  local module = require("api-browser.openapi")
  local db = require("api-browser.db")

  db.dbdir = "/tmp/"
  db.dbfile = "test_openapi.db"

  before_each(function()
    db.remove()
  end)

  after_each(function()
    db.remove()
  end)

  describe("selects the correct file or url to load", function()
    after_each(function()
      package.loaded["api-browser.config"] = nil
    end)

    it("prefers openapi_file if configured", function()
      local conf = require("api-browser.config")
      conf.setup({
        selected_api = "test/fixtures/openapi.yaml",
      })
      module.load()
    end)
  end)

  describe("pet api", function()
    module.parse_file("test/fixtures/openapi.yaml")

    it("has ten endpoints", function() 
      local result = module.parse_endpoints()
      assert.is_not.same(nil, result)
      assert.are.equal(10, #result)
      assert.are.equal(result[1].url, "/cat/{catId}.json")
      assert.are.equal(result[2].url, "/cat/{catId}.xml")
      assert.are.equal(result[3].url, "/cat_or_dog/cat.json")
      assert.are.equal(result[4].url, "/cat_or_dog/cat.xml")
      assert.are.equal(result[5].url, "/cat_or_dog/dog.json")
      assert.are.equal(result[6].url, "/cat_or_dog/dog.xml")
      assert.are.equal(result[7].url, "/cats.json")
      assert.are.equal(result[8].url, "/cats.xml")
      assert.are.equal(result[9].url, "/pets.json")
      assert.are.equal(result[10].url, "/pets.xml")
    end)
  end)

  describe("refs are split", function()
    it("split a ref correctly", function()
      local split = module.split_ref("#/components/parameters/format/name")
      assert.is_not_nil(split)
      assert.are.same({"components", "parameters", "format", "name"}, split)
    end)
  end)

  describe("replace path placeholders", function()
    it("with defaults", function()
      local endpoint = {
        url = "/cat/{catId}.{_format}",
        replaced = {},
      }
      local defaults = {
        catId = {
          name = "catId",
          ["in"] = "path",
          ["schema"] = {
            default = "123",
          }
        },
        format = {
          name = "_format",
          ["in"] = "path",
          ["schema"] = {
            -- should only return the default
            example = "xml",
            default = "json",
          }
        }
      }
      local result = module.replace_placeholders(endpoint, defaults)
      assert.is_not_nil(result)
      assert.are.same(4, #result)
      assert.are.same("/cat/123.json", result[1].url)
      assert.are.same("/cat/123.{_format}", result[2].url)
      assert.are.same("/cat/{catId}.json", result[3].url)
      assert.are.same("/cat/{catId}.{_format}", result[4].url)
    end)

    it("with example", function()
      local endpoint = {
        url = "/cat/{catId}.{_format}",
        replaced = {},
      }
      local defaults = {
        catId = {
          name = "catId",
          ["in"] = "path",
          ["schema"] = {
            -- returns the example when no default is set
            example = "123",
          }
        },
      }
      local result = module.replace_placeholders(endpoint, defaults)
      assert.is_not_nil(result)
      assert.are.same(2, #result)
      assert.are.same("/cat/123.{_format}", result[1].url)
      assert.are.same("/cat/{catId}.{_format}", result[2].url)
    end)

    it("with enums", function()
      local endpoint = {
        url = "/cat/{catId}.{_format}",
        replaced = {},
      }
      local defaults = {
        catId = {
          name = "catId",
          ["in"] = "path",
          ["schema"] = {
            default = "123",
          }
        },
        format = {
          name = "_format",
          ["in"] = "path",
          ["schema"] = {
            type = "string",
            enum = {"json", "xml"},
          }
        }
      }
      local result = module.replace_placeholders(endpoint, defaults)
      assert.is_not_nil(result)
      assert.are.same(4, #result)
      assert.are.same("/cat/123.json", result[1].url)
      assert.are.same("/cat/123.xml", result[2].url)
      assert.are.same("/cat/{catId}.json", result[3].url)
      assert.are.same("/cat/{catId}.xml", result[4].url)
    end)

    it("without defaults or examples", function()
      local endpoint = {
        url = "/cat/{catId}.{_format}",
        replaced = {},
      }
      local defaults = {
        catId = {
          name = "catId",
          ["in"] = "path",
          ["schema"] = {
            type = "integer",
          }
        },
        format = {
          name = "_format",
          ["in"] = "path",
          ["schema"] = {
            type = "string",
            enum = {"json", "xml"},
          }
        }
      }
      local result = module.replace_placeholders(endpoint, defaults)
      assert.is_not_nil(result)
      assert.are.same(2, #result)
    end)
  end)

  describe("refs lookup", function()
    module.parse_file("test/fixtures/openapi.yaml")
    it("finds the correct ref", function()
      local ref = "#/components/parameters/format"
      local refs = module.split_ref(ref)
      local result = module.lookup_ref(module.json, refs)
      assert.is_not_nil(result)
      assert.are.equal("_format", result.name)
    end)
  end)

end)

