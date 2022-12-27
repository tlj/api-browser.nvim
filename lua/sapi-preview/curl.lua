local files = require('sapi-preview.files')
local Job = require('plenary.job')

local M = {}

local function get_os_command_output(cmd, cwd)
  local command = table.remove(cmd, 1)
  local stderr = {}
  local stdout, ret = Job:new({
    command = command,
    args = cmd,
    cwd = cwd,
    on_stderr = function(_, data)
      table.insert(stderr, data)
    end,
  }):sync(60000)
  return stdout, ret, stderr
end

function M.fetch(url, opts)
  opts = opts or {}

  local result = {
    status = 0,
    headers = {},
    body = {},
  }

  local headers_file = '/tmp/sapi_preview.headers'

  local body, ret, _ = get_os_command_output(
    { "curl", "-D", headers_file, "-s", url },
    opts.cwd
  )
  if ret ~= 0 then
    error("Error " .. ret .. " while calling curl -s " .. url)
    return result
  end

  result.body = body
  local header_lines = files.lines_from(headers_file)
  for _, v in pairs(header_lines) do
    v = v:gsub("\r\n", "\n")

    local status = string.match(v, '^HTTP/%d.%d (%d+) ')
    if status ~= nil then
      result.status = tonumber(status)
    end

    local name, value = string.match(v, "(.-):%s*(.-)$")
    if name ~= nil and value ~= nil then
      result.headers[name] = value
    end
  end

  return result
end


return M
