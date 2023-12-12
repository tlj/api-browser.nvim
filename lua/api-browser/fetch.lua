local curl = require("api-browser.curl")
local utils = require("api-browser.utils")

local M = {}

function M.fetch_and_display(endpointInput, opts)
  opts = opts or {}

  local endpoint
  if type(endpointInput) == "table" then
    endpoint = endpointInput
  else
    endpoint = vim.fn.json_decode(endpointInput)
  end

  if opts.format == nil then
    opts.format = true
  end

  local fetchUrl = endpoint.base_url .. endpoint.url

  local buf_name = fetchUrl
  local buf = opts.buf

  if not buf then
    buf = utils.new_or_existing_buffer(buf_name, 'botright vnew')
  end

  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_name(buf, buf_name)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<cr>', {})
  if opts.diff then
    vim.cmd('diffthis')
  end

  if utils.content_type(endpoint) == "application/xml" then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'html')
  end

  if utils.content_type(endpoint) == "application/json" then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
  end

  local function on_exit(result)
    if vim.fn.bufexists(buf) == 0 then
      vim.notify("Buffer closed for " .. fetchUrl .. " - unable to update.")
      return
    end
    local lines = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, 0, lines, false, {})
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_put(result.output, "", false, false)
    end)
    if result.status_code == 0 then
      vim.print(vim.inspect(result))
      vim.print("Got status code 0 for " .. fetchUrl)
      vim.api.nvim_buf_call(buf, function()
        vim.api.nvim_put({"Error fetching " .. fetchUrl .. ". See :messages for more info."}, "", false, false)
      end)
    elseif result.status_code ~= 200 then
      vim.print("Got status code " .. result.status_code .. " for " .. fetchUrl)
    end
    if opts.debug then
      require("api-browser.dap").stop()
    end
  end

--  print("Fetching " .. fetchUrl .. "... ")
  curl.fetch_async(endpoint, on_exit)
end

return M
