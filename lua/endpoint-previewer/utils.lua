local M = {}

function M.ends_with(str, ending)
  return ending == "" or str:sub(-#ending) == ending
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
