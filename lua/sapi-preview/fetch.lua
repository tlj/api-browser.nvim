local db = require("sapi-preview.db")
local curl = require("sapi-preview.curl")
local utils = require("sapi-preview.utils")

local M = {}

function M.fetch_and_display(fetchUrl, opts)
  opts = opts or {}

  if opts.format == nil then
    opts.format = true
  end

  local buf = opts.buf

  if not buf then
    vim.api.nvim_command('botright vnew')

    buf = vim.api.nvim_get_current_buf()
  else
    vim.api.nvim_set_current_buf(buf)
  end

  local buf_name = fetchUrl:gsub("/", "_")
  vim.api.nvim_buf_set_name(buf, buf_name)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  print("Fetching " .. fetchUrl .. "... ")

  local res = curl.fetch(fetchUrl, opts)
  if res.status ~= 200 then
    error("Status was not 200 - " .. res.status .. " for " .. fetchUrl)
    return
  end

  if utils.ends_with(fetchUrl, '.xml') then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'html')
  end

  if utils.ends_with(fetchUrl, '.json') then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'json')
  end

  vim.api.nvim_put(res.body, "", false, false)
end

return M
