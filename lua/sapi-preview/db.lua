local sqlite = require "sqlite"
local sqlite_uri = "/tmp/sapi_nvim_history.sqlite3"

local M = {}
local db = {}

function M.init()
  db = sqlite {
    uri = sqlite_uri,
    entries = {
     id = true,
     url = "text",
     last_used = { "timestamp", default = sqlite.lib.strftime("%s", "now") }
    },
  }
end

function M.get_entries()
  if next(db) == nil then
    M.init()
  end
  return db.entries:get()
end

function M.insert_or_update(fetchUrl)
  if next(db) == nil then
    M.init()
  end

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
