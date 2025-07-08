local M = {}

local config = require("cc_nvim.config")
local panel = require("cc_nvim.panel")
local claude = require("cc_nvim.claude")
local utils = require("cc_nvim.utils")

M.config = config
M.panel = panel
M.claude = claude
M.utils = utils

function M.setup(opts)
  config.setup(opts)
  panel.setup()
end

function M.chat(message)
  panel.open()
  if message and message ~= "" then
    claude.send_message(message)
  end
end

function M.send_file(file_path)
  local path = file_path or vim.fn.expand("%:p")
  if not path or path == "" then
    vim.notify("No file to send", vim.log.levels.WARN)
    return
  end

  local content = utils.read_file(path)
  if content then
    panel.open()
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
  panel.open()
  claude.send_selection(selection)
end

function M.apply_changes()
  claude.apply_changes()
end

function M.review_changes()
  local changes = claude.get_pending_changes()
  if #changes == 0 then
    vim.notify("No changes to review", vim.log.levels.WARN)
    return
  end
  
  local diff = require("cc_nvim.diff")
  diff.start_diff_mode(changes)
end

function M.git_diff(commit_or_branch)
  local diff = require("cc_nvim.diff")
  diff.start_git_diff_mode(commit_or_branch)
end

function M.toggle_panel()
  panel.toggle()
end

return M

