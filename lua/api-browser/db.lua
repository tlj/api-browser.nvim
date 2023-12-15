local sqlite = require "sqlite"

local M = {
  dbdir = vim.fn.stdpath "data" .. "/databases/",
  dbfile = "api-browser.db"
}
local db = {}

function M.init()
  if next(db) == nil then
    if not vim.loop.fs_stat(M.dbdir) then
      vim.loop.fs_mkdir(M.dbdir, 493)
    end
    db = sqlite {
      uri = M.dbdir .. M.dbfile,
      entries = {
        id = true,
        workspace = "text",
        name = "text",
        endpoint = "text",
        last_used = { "timestamp", default = sqlite.lib.strftime("%s", "now") }
      },
      defaults = {
        workspace = "text",
        name = "text",
        value = "text",
      }
   }
  end
end

function M.remove()
  pcall(os.remove, M.dbdir .. M.dbfile)
  db = {}
end

function M.set_default(workspace, name, value)
  M.init()

  local existing = db.defaults:where { workspace = workspace, name = name }
  if existing == nil then
    db.defaults:insert { workspace = workspace, name = name, value = value }
  else
    db.defaults:update {
      where = { workspace = workspace, name = name },
      set = { value = value },
    }
  end
end

function M.get_default(workspace, name)
  M.init()

  local val = db.defaults:where { workspace = workspace, name = name }
  if val == nil then
    return nil
  end

  return val.value
end

function M.clear_cache(workspace)
  M.init()
  db.entries:remove { workspace = workspace }
end

function M.get_entries(workspace)
  M.init()

  return db.entries:get({ workspace = workspace }) or {}
end

function M.push_history(workspace, endpoint)
  M.init()

  local existing = db.entries:where { workspace = workspace, name = endpoint.display_name }
  if existing == nil then
    db.entries:insert { workspace = workspace, name = endpoint.display_name, endpoint = vim.fn.json_encode(endpoint) }
  else
    local ts = os.time(os.date("*t"))
    db.entries:update {
      where = { id = existing.id },
      set = { last_used = ts }
    }
  end
end

return M
