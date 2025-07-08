local M = {}

function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()
  return content
end

function M.write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false
  end

  file:write(content)
  file:close()
  return true
end

function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  if #lines == 0 then
    return nil
  end

  if #lines == 1 then
    return string.sub(lines[1], start_pos[3], end_pos[3])
  else
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    return table.concat(lines, "\n")
  end
end

function M.get_current_word()
  return vim.fn.expand("<cword>")
end

function M.get_current_line()
  return vim.api.nvim_get_current_line()
end

function M.get_buffer_content(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, "\n")
end

function M.split_lines(str)
  local lines = {}
  if str == "" then
    return {""}
  end
  
  local start = 1
  while true do
    local pos = str:find("\n", start)
    if not pos then
      table.insert(lines, str:sub(start))
      break
    end
    table.insert(lines, str:sub(start, pos - 1))
    start = pos + 1
  end
  
  return lines
end

function M.escape_pattern(str)
  return str:gsub("([^%w])", "%%%1")
end

function M.is_binary_file(path)
  local file = io.open(path, "rb")
  if not file then
    return false
  end

  local chunk = file:read(1024)
  file:close()

  if not chunk then
    return false
  end

  for i = 1, #chunk do
    local byte = string.byte(chunk, i)
    if byte == 0 then
      return true
    end
  end

  return false
end

function M.get_file_extension(path)
  return path:match("%.([^%.]+)$")
end

function M.get_relative_path(path, base)
  base = base or vim.fn.getcwd()

  if path:sub(1, #base) == base then
    return path:sub(#base + 2)
  end

  return path
end

function M.debounce(func, wait)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer then
      timer:stop()
      timer:close()
    end
    timer = vim.loop.new_timer()
    timer:start(wait, 0, function()
      timer:stop()
      timer:close()
      timer = nil
      vim.schedule(function()
        func(unpack(args))
      end)
    end)
  end
end

return M

