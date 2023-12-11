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
        selected_api = "test/fixtures/petstore.json",
      })
      module.load()
    end)
  end)

  describe("pet api", function()
    module.parse_file("test/fixtures/petstore.json")

    it("has all endpoints", function() 
      local result = module.parse_endpoints()
      assert.is_not.same(nil, result)
      assert.are.equal(16, #result)
      local expected = { {
    api = "",
    display_name = "/pet/findByStatus?status=available (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/pet/findByStatus",
    placeholders = {},
    replaced = {
      status = "available"
    },
    requirements = {},
    url = "/pet/findByStatus?status=available"
  }, {
    api = "",
    display_name = "/pet/findByStatus?status=available (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/pet/findByStatus",
    placeholders = {},
    replaced = {
      status = "available"
    },
    requirements = {},
    url = "/pet/findByStatus?status=available"
  }, {
    api = "",
    display_name = "/pet/findByStatus?status={status} (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/pet/findByStatus",
    placeholders = {
      status = { "available", "pending", "sold" }
    },
    replaced = {},
    requirements = {},
    url = "/pet/findByStatus?status={status}"
  }, {
    api = "",
    display_name = "/pet/findByStatus?status={status} (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/pet/findByStatus",
    placeholders = {
      status = { "available", "pending", "sold" }
    },
    replaced = {},
    requirements = {},
    url = "/pet/findByStatus?status={status}"
  }, {
    api = "",
    display_name = "/pet/findByTags?tags={tags} (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/pet/findByTags",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/pet/findByTags?tags={tags}"
  }, {
    api = "",
    display_name = "/pet/findByTags?tags={tags} (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/pet/findByTags",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/pet/findByTags?tags={tags}"
  }, {
    api = "",
    display_name = "/pet/{petId} (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/pet/{petId}",
    placeholders = {
      petId = "^\\d+$"
    },
    replaced = {},
    requirements = {},
    url = "/pet/{petId}"
  }, {
    api = "",
    display_name = "/pet/{petId} (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/pet/{petId}",
    placeholders = {
      petId = "^\\d+$"
    },
    replaced = {},
    requirements = {},
    url = "/pet/{petId}"
  }, {
    api = "",
    display_name = "/store/inventory (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/store/inventory",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/store/inventory"
  }, {
    api = "",
    display_name = "/store/order/{orderId} (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/store/order/{orderId}",
    placeholders = {
      orderId = "^\\d+$"
    },
    replaced = {},
    requirements = {},
    url = "/store/order/{orderId}"
  }, {
    api = "",
    display_name = "/store/order/{orderId} (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/store/order/{orderId}",
    placeholders = {
      orderId = "^\\d+$"
    },
    replaced = {},
    requirements = {},
    url = "/store/order/{orderId}"
  }, {
    api = "",
    display_name = "/user/login?username={username}&password={password} (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/user/login",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/user/login?username={username}&password={password}"
  }, {
    api = "",
    display_name = "/user/login?username={username}&password={password} (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/user/login",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/user/login?username={username}&password={password}"
  }, {
    api = "",
    display_name = "/user/logout",
    headers = {},
    original_url = "/user/logout",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/user/logout"
  }, {
    api = "",
    display_name = "/user/{username} (application/json)",
    headers = {
      ["Content-Type"] = "application/json"
    },
    original_url = "/user/{username}",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/user/{username}"
  }, {
    api = "",
    display_name = "/user/{username} (application/xml)",
    headers = {
      ["Content-Type"] = "application/xml"
    },
    original_url = "/user/{username}",
    placeholders = {},
    replaced = {},
    requirements = {},
    url = "/user/{username}"
  } }
      for kexp in pairs(expected) do
        assert.are.same(expected[kexp], result[kexp])
      end
    end)
  end)

  describe("endpoint name includes content type", function()
    local endpoint = {
      url = "/pets",
      headers = {
        ["Content-Type"] = "application/json"
      },
    }
    assert.are.same("/pets (application/json)", module.endpoint_display_name(endpoint))
  end)

  describe("finds endpoints by parameter pattern match", function()
    local value = "pending"
    local matching = module.get_endpoint_by_param_pattern(value)

    local expected = { {
      api = "",
      display_name = "/pet/findByStatus?status=pending (application/json)",
      headers = {
        ["Content-Type"] = "application/json"
      },
      original_url = "/pet/findByStatus",
      placeholders = {},
      replaced = {
        status = "pending"
      },
      requirements = {},
      url = "/pet/findByStatus?status=pending"
    }, {
        api = "",
        display_name = "/pet/findByStatus?status=pending (application/xml)",
        headers = {
          ["Content-Type"] = "application/xml"
        },
        original_url = "/pet/findByStatus",
        placeholders = {},
        replaced = {
          status = "pending"
        },
        requirements = {},
        url = "/pet/findByStatus?status=pending"
      }}

    assert.is_not_nil(matching)
    assert.are.same(2, #matching)
    for kexp in pairs(expected) do
      assert.are.same(expected[kexp], matching[kexp])
    end
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
        placeholders = {}
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
        placeholders = {},
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
        placeholders = {},
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
        placeholders = {},
      }
      local defaults = {
        catId = {
          name = "catId",
          ["in"] = "path",
          ["schema"] = {
            type = "string",
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
      local expected = {
        {
          ["url"] = "/cat/{catId}.json",
          replaced = {
            ["_format"] = "json",
          },
          placeholders = {}
        },
        {
          ["url"] = "/cat/{catId}.xml",
          replaced = {
            ["_format"] = "xml",
          },
          placeholders = {}
        }
      }
      local result = module.replace_placeholders(endpoint, defaults)
      assert.is_not_nil(result)
      assert.are.same(2, #result)
      assert.are.same(expected, result)
    end)
  end)

  describe("add query parameters", function()
    it("required", function()
      local endpoint = {
        url = "/pets",
        replaced = {},
        placeholders = {},
      }
      local defaults = {
        limit = {
          name = "limit",
          ["in"] = "query",
          required = false,
          ["schema"] = {
            -- should only return the default
            type = "integer",
            minimum = "0",
            maximum = "10",
            default = "10",
          }
        },
        offset = {
          name = "offset",
          ["in"] = "query",
          required = false,
          ["schema"] = {
            -- should only return the default
            type = "integer",
            minimum = "0",
            maximum = "10",
            default = "0",
          }
        }
      }
      local exploded = module.explode_query_parameters(endpoint, defaults)
      local result = module.replace_placeholders(exploded, defaults)
      assert.is_not_nil(result)
      assert.are.same(4, #result)
      assert.are.same("/pets?limit=10&offset=0", result[1].url)
      assert.are.same("/pets?limit=10&offset={offset}", result[2].url)
      assert.are.same("/pets?limit={limit}&offset=0", result[3].url)
      assert.are.same("/pets?limit={limit}&offset={offset}", result[4].url)
    end)
  end)

  describe("refs lookup", function()
    module.parse_file("test/fixtures/petstore.json")
    it("finds the correct ref", function()
      local ref = "#/components/schemas/Order"
      local refs = module.split_ref(ref)
      local result = module.lookup_ref(module.json, refs)
      assert.is_not_nil(result)
      assert.are.equal("order", result.xml.name)
    end)
  end)

end)

