local db = require("endpoint-previewer.db")
local fetch = require("endpoint-previewer.fetch")
local conf = require("endpoint-previewer.config")

local M = {}

function M.telescope_debug_endpoint(buf)
  M.telescope_select_endpoint(buf, {debug = true})
end

function M.telescope_select_endpoint(buf, opts)
  opts = opts or {}

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

  if opts.debug then
    require("endpoint-previewer.dap").start()
  end

  local base_url = conf.set_selected_env()
  vim.api.nvim_command('botright vnew')
  local nbuf = vim.api.nvim_get_current_buf()
  if opts.debug then
    vim.defer_fn(function()
      fetch.fetch_and_display(base_url .. selected, vim.tbl_extend("force", opts, {buf = nbuf}))
    end, 500)
  else
    vim.schedule(function()
      fetch.fetch_and_display(base_url .. selected, vim.tbl_extend("force", opts, {buf = nbuf}))
    end)
  end
end

function M.telescope_diff_endpoint(buf, opts)
  opts = opts or {}
  opts.diff = true
  M.telescope_compare_endpoint(buf, opts)
end

function M.telescope_compare_endpoint(buf, opts)
  opts = opts or {}

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
  local win1opts = {}
  win1opts['scope'] = 'local'
  win1opts['win'] = win1
  vim.api.nvim_set_option_value("wrap", false, win1opts)
  vim.api.nvim_win_set_option(win1, "wrap", false)

  vim.api.nvim_command('rightbelow new')
  local buf2 = vim.api.nvim_get_current_buf()
  local win2 = vim.api.nvim_get_current_win()
  local win2opts = {}
  win2opts['scope'] = 'local'
  win2opts['win'] = win2
  vim.api.nvim_set_option_value("wrap", false, win2opts)
  vim.api.nvim_win_set_option(win2, "scrollbind", true)

  local remote_base_url = conf.selected_remote_base_url()
  local base_url = conf.selected_base_url()
  vim.schedule(function()
    fetch.fetch_and_display(remote_base_url .. selected, vim.tbl_extend("force", opts, {buf = buf1}))
  end)
  vim.schedule(function()
    fetch.fetch_and_display(base_url .. selected, vim.tbl_extend("force", opts, {buf = buf2}))
  end)
end

return M
