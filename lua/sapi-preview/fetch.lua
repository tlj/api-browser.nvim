local db = require("sapi-preview.db")
local curl = require("sapi-preview.curl")
local utils = require("sapi-preview.utils")

local M = {}

function M.fetch_and_display(fetchUrl, opts)
  opts = opts or {}

  if opts.format == nil then
    opts.format = true
  end

  if opts.save_history then
    db.push_history(fetchUrl)
  end

  local res = curl.fetch(fetchUrl, opts)

  if res.status ~= 200 then
    error("Status was not 200 - " .. res.status .. " for " .. fetchUrl)
    return
  end

  vim.api.nvim_command('botright vnew')

  local buf = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_set_name(buf, 'fetched ' .. fetchUrl)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  if utils.ends_with(fetchUrl, '.xml') then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'xml')
  end

  if utils.ends_with(fetchUrl, '.json') then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
  end

  vim.api.nvim_put(res.body, "", true, false)
end

return M
