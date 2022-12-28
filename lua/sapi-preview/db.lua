local sqlite = require "sqlite"
local sqlite_uri = "/tmp/sapi_nvim_history.sqlite3"

local M = {}
local db = {}

function M.init()
  if next(db) == nil then
    db = sqlite {
      uri = sqlite_uri,
      entries = {
       id = true,
       url = "text",
       last_used = { "timestamp", default = sqlite.lib.strftime("%s", "now") }
      },
      defaults = {
        name = "text",
        value = "text",
      },
      packages = {
        id = true,
        name = "text",
        version = "text",
      },
      endpoints = {
        id = true,
        url = "text",
        package_url = "text",
      },
      requirements = {
        id = true,
        package_url = "text",
        name = "text",
        value = "text",
      }
    }
  end
end

function M.set_default(name, value)
  M.init()

  local existing = db.defaults:where { name = name }
  if existing == nil then
    db.defaults:insert { name = name, value = value }
  else
    db.defaults:update {
      where = { name = name },
      set = { value = value },
    }
  end
end

function M.get_default(name)
  M.init()

  local val = db.defaults:where { name = name }
  if val == nil then
    return nil
  end

  return val.value
end

function M.clear_cache()
  M.init()
  M.clear_packages()
  db.entries:remove()
  db.endpoints:remove()
  db.requirements:remove()
end

function M.clear_package_endpoints(package_url)
  M.init()

  db.endpoints:remove({ package_url = package_url })
  db.requirements:remove({ package_url = package_url })
end

function M.add_package_requirement(package_url, name, value)
  M.init()

  local existing = db.requirements:where { package_url = package_url, name = name }
  if existing == nil then
    db.requirements:insert({package_url = package_url, name = name, value = value })
  else
    db.endpoints:update({
      where = { package_url = package_url, name = name },
      set = { value = value }
    })
  end
end

function M.get_package_requirements(package_url)
  M.init()

  return db.requirements:get({ where = { package_url = package_url }})
end

function M.add_package_endpoint(package_url, url)
  M.init()

  local existing = db.endpoints:where { package_url = package_url, url = url }
  if existing == nil then
    db.endpoints:insert({ package_url = package_url, url = url })
  end
end

function M.get_package_endpoints(package_url)
  M.init()

  return db.endpoints:get({ where = { package_url = package_url }})
end

function M.clear_packages()
  M.init()

  return db.packages:remove()
end

function M.add_package(name, version)
  M.init()

  local existing = db.packages:where { name = name, version = version }
  if existing == nil then
    db.packages:insert { name = name, version = version }
  end
end

function M.get_packages()
  M.init()

  return db.packages:get()
end

function M.get_entries()
  M.init()

  return db.entries:get()
end

function M.push_history(fetchUrl)
  M.init()

  local existing = db.entries:where { url = fetchUrl }
  if existing == nil then
    db.entries:insert { url = fetchUrl }
  else
    local ts = os.time(os.date("!*t"))
    db.entries:update {
      where = { id = existing.id },
      set = { last_used = ts }
    }
  end
end

return M
