local files = require('sapi-preview.files')
local Job = require('plenary.job')
local utils = require('sapi-preview.utils')

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

local function format_output(url, body_file, opts)
  opts = opts or {}

  local original_body = files.lines_from(body_file)

  local commands = {
    json = { "jq", ".", body_file },
    xml = { "xmllint", "-format", body_file },
  }

  for ext, cmd in pairs(commands) do
    if utils.ends_with(url, ext) then
      local body, ret, err = get_os_command_output(
        cmd,
        opts.cwd
      )
      if ret ~= 0 then
        print("Error " .. ret .. " while calling " .. cmd[1] .. " to format output: " .. err[1])
        return original_body
      end
      return body
    end
  end

  print("No matching formatter found for " .. url)
  return original_body
end

function M.fetch(url, opts)
  opts = opts or {}

  local result = {
    status = 0,
    headers = {},
    body = {},
  }

  local headers_file = os.tmpname() -- '/tmp/sapi_preview.headers'
  local body_file = os.tmpname() -- '/tmp/sapi_preview.body'

  local _, ret, _ = get_os_command_output(
    { "curl", "-D", headers_file, "-o", body_file, "-s", url },
    opts.cwd
  )
  if ret ~= 0 then
    error("Error " .. ret .. " while calling curl -s " .. url)
    return result
  end

  if opts.format then
    result.body = format_output(url, body_file, opts)
  else
    result.body = files.lines_from(body_file)
  end

  local header_lines = files.lines_from(headers_file)
  for _, v in pairs(header_lines) do
    v = v:gsub("\r\n", "\n")

    local status = string.match(v, '^HTTP/.- (%d+) ')
    if status ~= nil then
      result.status = tonumber(status)
    end

    local name, value = string.match(v, "(.-):%s*(.-)$")
    if name ~= nil and value ~= nil then
      result.headers[name] = value
    end
  end

  os.remove(headers_file)
  os.remove(body_file)

  return result
end


return M
