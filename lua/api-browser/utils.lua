local M = {}

function M.new_or_existing_buffer(name, pos, opt)
  opt = opt or {}
  for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == name then
      local lines = vim.api.nvim_buf_line_count(bufnr)
      vim.api.nvim_buf_set_lines(bufnr, 0, lines, false, {})
      if not opt.noplaceholder then
        vim.api.nvim_buf_call(bufnr, function()
          vim.api.nvim_put({"Fetching " .. name .. "..."}, "", false, false)
        end)
      end

      return bufnr
    end
  end

  vim.api.nvim_command(pos)

  if not opt.noplaceholder then
    vim.api.nvim_put({"Fetching " .. name .. "..."}, "", false, false)
  end

  return vim.api.nvim_get_current_buf()
end

function M.ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

function M.content_type(endpoint)
  if endpoint.headers["Content-Type"] then
    return endpoint.headers["Content-Type"]
  end
  if M.ends_with(endpoint.url, '.json') then
    return "application/json"
  end
  return ""
end

function M.split_lines(body)
  local body_lines = {}
  for s in body:gmatch("[^\r\n]+") do
    table.insert(body_lines, s)
  end
  return body_lines
end

function M.split_regex(ptn)
  local ptns = {}
  local size = 0
  for p in ptn:gmatch("[^|]+") do
    size = size + 1
    table.insert(ptns, p)
  end
  if size == 0 then
    table.insert(ptns, ptn)
  end
  return ptns
end

function M.map(maptbl, f)
  local t = {}
  for k, v in pairs(maptbl) do
    t[k] = f(v)
  end
  return t
end

return M
