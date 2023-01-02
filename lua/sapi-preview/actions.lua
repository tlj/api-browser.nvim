local db = require("sapi-preview.db")
local fetch = require("sapi-preview.fetch")
local conf = require("sapi-preview.config")

local M = {}

function M.telescope_select_endpoint(buf)
  require("telescope.actions").close(buf)
  local selection = require("telescope.actions.state").get_selected_entry()
  if not selection then
    require("telescope.utils").__warn_no_selection "builtin.builtin"
    return
  end

  local selected = selection[1]
  for idPlaceHolder in string.gmatch(selected, '{(%a+)}') do
    vim.ui.input({
      prompt = idPlaceHolder .. ": ",
    }, function(idInput)
      selected = string.gsub(selected, "{" .. idPlaceHolder .. "}", idInput)
    end)
  end

  db.push_history(selected)

  vim.api.nvim_command('botright vnew')
  local nbuf = vim.api.nvim_get_current_buf()
  vim.schedule(function()
    fetch.fetch_and_display(conf.options.base_url .. selected, {buf = nbuf})
  end)
end

function M.telescope_compare_endpoint(buf)
  require("telescope.actions").close(buf)

  local selection = require("telescope.actions.state").get_selected_entry()
  if not selection then
    require("telescope.utils").__warn_no_selection "builtin.builtin"
  end

  local selected = selection[1]
  for idPlaceHolder in string.gmatch(selected, '{(%a+)}') do
    vim.ui.input({
      prompt = idPlaceHolder .. ": ",
    }, function(idInput)
      selected = string.gsub(selected, "{" .. idPlaceHolder .. "}", idInput)
    end)
  end

  db.push_history(selected)

  vim.api.nvim_command('botright vnew')
  local buf1 = vim.api.nvim_get_current_buf()
  local win1 = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_option(win1, "scrollbind", true)

  vim.api.nvim_command('rightbelow new')
  local buf2 = vim.api.nvim_get_current_buf()
  local win2 = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_option(win2, "scrollbind", true)

  vim.schedule(function()
    fetch.fetch_and_display(conf.options.base_urls[1] .. selected, {buf = buf1})
  end)
  vim.schedule(function()
    fetch.fetch_and_display(conf.options.base_urls[2] .. selected, {buf = buf2})
  end)
end

return M
