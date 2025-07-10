local M = {}

local config = require("cc_nvim.config")
local claude = require("cc_nvim.core.claude")
local utils = require("cc_nvim.utils")

M.config = config
M.claude = claude
M.utils = utils

function M.setup(opts)
  config.setup(opts)
end

function M.open()
  claude.open_terminal()
end

function M.close()
  claude.close()
end

function M.toggle()
  claude.toggle()
end

function M.send_file(file_path)
  local path = file_path or vim.fn.expand("%:p")
  if not path or path == "" then
    vim.notify("No file to send", vim.log.levels.WARN)
    return
  end

  local content = utils.read_file(path)
  if content then
    claude.send_file(path, content)
  else
    vim.notify("Failed to read file: " .. path, vim.log.levels.ERROR)
  end
end

function M.send_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    vim.notify("No selection found", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  if #lines == 0 then
    vim.notify("No selection found", vim.log.levels.WARN)
    return
  end

  local selection = table.concat(lines, "\n")
  claude.send_selection(selection)
end

function M.send_message(message)
  claude.send_message(message)
end

function M.is_open()
  return claude.is_terminal_open()
end

return M