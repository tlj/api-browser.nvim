local files = require('endpoint-previewer.files')
local Job = require('plenary.job')
local utils = require('endpoint-previewer.utils')

local M = {}

M.fetch_async = function(url, callback, opts)
  opts = opts or {}

  local headers_file = os.tmpname()
  local body_file = os.tmpname()

  local command = "curl"
  local args = { "-D", headers_file, "-o", body_file, "-s", url }

  local stdout = {}
  local stderr = {}

  Job:new({
    command = command,
    args = args,
    on_stdout = function(_, line)
      table.insert(stdout, line)
    end,
    on_stderr = function(_, line)
      table.insert(stderr, line)
    end,
    on_exit = vim.schedule_wrap(function(_, exit_code)
      local headers = M.parse_headers(headers_file)
      local output = M.format_output(url, body_file)

      local result = {
        stdout = stdout,
        stderr = stderr,
        headers = headers.headers,
        status_code = headers.status,
        output = output,
        exit_code = exit_code,
      }

      callback(result)
    end)
  }):start()
end

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

M.format_output = function(url, body_file, opts)
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

function M.parse_headers(headers_file)
  local result = {
    status = 0,
    headers = {},
  }
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
  return result
end

function M.fetch(url, opts)
  opts = opts or {}

  local result = {
    status = 0,
    headers = {},
    body = {},
  }

  local headers_file = os.tmpname()
  local body_file = os.tmpname()

  local _, ret, _ = get_os_command_output(
    { "curl", "-D", headers_file, "-o", body_file, "-s", url },
    opts.cwd
  )
  if ret ~= 0 then
    error("Error " .. ret .. " while calling curl -s " .. url)
    return result
  end

  if opts.format then
    result.body = M.format_output(url, body_file, opts)
  else
    result.body = files.lines_from(body_file)
  end

  local parsed_headers = M.parse_headers(headers_file)
  result.status = parsed_headers.status
  result.headers = parsed_headers.headers

  os.remove(headers_file)
  os.remove(body_file)

  return result
end


return M
