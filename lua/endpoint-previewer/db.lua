local sqlite = require "sqlite"
local dbdir = vim.fn.stdpath "data" .. "/databases"

local M = {}
local db = {}

function M.init()
  if next(db) == nil then
    if not vim.loop.fs_stat(dbdir) then
      vim.loop.fs_mkdir(dbdir, 493)
    end
    db = sqlite {
      uri = dbdir .. "/endpoint-previewer.db",
      entries = {
       id = true,
       url = "text",
       last_used = { "timestamp", default = sqlite.lib.strftime("%s", "now") }
      },
      defaults = {
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
  db.entries:remove()
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
    local ts = os.time(os.date("*t"))
    db.entries:update {
      where = { id = existing.id },
      set = { last_used = ts }
    }
  end
end

return M
