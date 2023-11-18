local M = {}

local state = {
  opened = false,
  started = false,
}

M.start = function()
  local dapuiok, _ = pcall(require, 'dapui')
  if dapuiok then
    require("dapui").open()
    state.opened = true
  else
    print(
      "Unable to start the DAP UI for debugger. " ..
      "Try `:checkhealth api-browser` to confirm if it is installed."
    )
  end

  local dapok, _ = pcall(require, 'dap')
  if dapok then
    require("dap").continue()
    state.started = true
  else
    print(
      "Unable to start DAP debugger. " ..
      "Try `:checkhealth api-browser` to confirm if it is installed."
    )
  end
end

M.stop = function()
  local dapuiok, _ = pcall(require, 'dapui')
  if dapuiok and state.opened then
    require('dapui').close()
  end

  local dapok, _ = pcall(require, 'dap')
  if dapok and state.started then
    require('dap').close()
  end
end

return M
