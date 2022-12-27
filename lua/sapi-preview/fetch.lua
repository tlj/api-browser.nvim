local db = require("sapi-preview.db")
local curl = require("sapi-preview.curl")
local utils = require("sapi-preview.utils")

local M = {}

function M.fetch_and_display(fetchUrl, opts)
  opts = opts or {}

  db.insert_or_update(fetchUrl)

  local res = curl.fetch(fetchUrl)

  if res.status ~= 200 then
    error("Status was not 200 - " .. res.status)
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
