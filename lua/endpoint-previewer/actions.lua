local db = require("endpoint-previewer.db")
local fetch = require("endpoint-previewer.fetch")
local conf = require("endpoint-previewer.config")

local M = {}

function M.telescope_select_endpoint(buf)
-- multi select code
--  local num_selections = require("telescope.actions.state").get_current_picker(buf):get_multi_selection()
-- print(vim.inspect(num_selections))

  require("telescope.actions").close(buf)
  local selection = require("telescope.actions.state").get_selected_entry()
  if not selection then
    require("telescope.utils").__warn_no_selection "builtin.builtin"
    return
  end

  local selected = selection.value.url
  for _, idPlaceHolder in pairs(selection.value.placeholders or {}) do
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

  local selected = selection.value.url
  for _, idPlaceHolder in pairs(selection.value.placeholders or {}) do
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
