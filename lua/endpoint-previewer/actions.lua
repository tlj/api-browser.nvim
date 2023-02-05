local db = require("endpoint-previewer.db")
local Job = require('plenary.job')
local fetch = require("endpoint-previewer.fetch")
local conf = require("endpoint-previewer.config")
local utils = require("endpoint-previewer.utils")

local M = {}

function M.telescope_debug_endpoint(buf)
  M.telescope_select_endpoint(buf, {debug = true})
end

function M.telescope_test_api(buf, opts)
  opts = opts or {}

  require("telescope.actions").close(buf)
  local selection = require("telescope.actions.state").get_selected_entry()
  if not selection then
    require("telescope.utils").__warn_no_selection "builtin.builtin"
    return
  end

  vim.notify("Testing " .. selection.value.package .. " " .. selection.value.version)
end

function M.telescope_test_endpoint(buf, opts)
  opts = opts or {}

  require("telescope.actions").close(buf)
  local selection = require("telescope.actions.state").get_selected_entry()
  if not selection then
    require("telescope.utils").__warn_no_selection "builtin.builtin"
    return
  end

  local selected = selection.value.url
  for _, idPlaceHolder in pairs(selection.value.placeholders or {}) do
    local idInput = vim.fn.input(idPlaceHolder .. ": ")
    selected = string.gsub(selected, "{" .. idPlaceHolder .. "}", idInput)
  end

  db.push_history(selected)

  M.test_endpoint(selected, opts)
end

function M.test_endpoint(selected, opts)
  opts = opts or {}

  local base_url = conf.selected_base_url()
  local buf = utils.new_or_existing_buffer("api-tester " .. base_url .. selected, 'botright vnew', {noplaceholder = true})
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<cr>', {})
  vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

  local function on_stdout(output, idx)
    if vim.fn.bufexists(buf) == 0 then
      return
    end
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_buf_set_lines(buf, idx, idx, false, {output})
    end)
  end

  local remote_base_url = conf.selected_remote_base_url()
  local args = {
    "--config",
    "config/api-tester.yaml",
    "check",
    base_url .. selected,
    "--markdown",
  }
  if remote_base_url ~= "" then
    table.insert(args, "-p")
    table.insert(args, remote_base_url)
  end
  vim.schedule(function()
    local output = {}
    local idx = 0
    Job:new({
      command = "api-tester",
      args = args,
      on_stdout = function(_, line)
        vim.schedule(function()
          on_stdout(line, idx)
        end)
        idx = idx + 1
      end,
      on_stderr = function(_, line)
        vim.schedule(function()
          on_stdout(line, idx)
        end)
        idx = idx + 1
      end,
      on_exit = function(_, line)
        vim.schedule(function()
          on_stdout("Done", idx)
        end)
        idx = idx + 1
      end,
    }):start()
  end)
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
    local idInput = vim.fn.input(idPlaceHolder .. ": ")
    selected = string.gsub(selected, "{" .. idPlaceHolder .. "}", idInput)
  end

  db.push_history(selected)

  if opts.debug then
    require("endpoint-previewer.dap").start()
  end

  local base_url = conf.selected_base_url()
  local nbuf = utils.new_or_existing_buffer(base_url .. selected, 'botright vnew')
  local fetchUrl = base_url .. selected

  vim.api.nvim_buf_set_keymap(nbuf, 'n', 'r', ':lua require("endpoint-previewer.fetch").fetch_and_display("' .. fetchUrl .. '", {})<cr>', {})
  vim.api.nvim_buf_set_keymap(nbuf, 'n', 'd', ':lua require("endpoint-previewer.actions").diff_endpoint("' .. selected .. '", {})<cr>', {})
  vim.api.nvim_buf_set_keymap(nbuf, 'n', 't', ':lua require("endpoint-previewer.actions").test_endpoint("' .. selected .. '", {})<cr>', {})

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

  M.diff_endpoint(selected, opts)
end

function M.diff_endpoint(selected, opts)
  opts = opts or {}

  local remote_base_url = conf.selected_remote_base_url()
  local base_url = conf.selected_base_url()

  local buf1 = utils.new_or_existing_buffer(base_url .. selected, 'botright vnew')
  local win1 = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_option(win1, "scrollbind", true)
  local win1opts = {}
  win1opts['scope'] = 'local'
  win1opts['win'] = win1
  vim.api.nvim_set_option_value("wrap", false, win1opts)
  vim.api.nvim_win_set_option(win1, "wrap", false)

  local buf2 = utils.new_or_existing_buffer(remote_base_url .. selected, 'rightbelow new')
  local win2 = vim.api.nvim_get_current_win()
  local win2opts = {}
  win2opts['scope'] = 'local'
  win2opts['win'] = win2
  vim.api.nvim_set_option_value("wrap", false, win2opts)
  vim.api.nvim_win_set_option(win2, "scrollbind", true)

  vim.schedule(function()
    fetch.fetch_and_display(remote_base_url .. selected, vim.tbl_extend("force", opts, {buf = buf1}))
  end)
  vim.schedule(function()
    fetch.fetch_and_display(base_url .. selected, vim.tbl_extend("force", opts, {buf = buf2}))
  end)
end

return M
