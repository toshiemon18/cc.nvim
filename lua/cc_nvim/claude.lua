local M = {}

local config = require("cc_nvim.config")
local panel = require("cc_nvim.panel")
local diff_parser = require("cc_nvim.diff_parser")
local uv = vim.loop

M.current_session = nil
M.message_history = {}
M.pending_changes = {}

function M.start_session()
  if M.current_session then
    return M.current_session
  end

  local claude_cmd = config.get("claude_executable")
  local handle, pid = uv.spawn(claude_cmd, {
    args = {},
    stdio = { uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false) }
  }, function(code, signal)
    M.current_session = nil
    if code ~= 0 then
      vim.notify("Claude Code session ended with code: " .. code, vim.log.levels.ERROR)
    end
  end)

  if not handle then
    vim.notify("Failed to start Claude Code: " .. (pid or "unknown error"), vim.log.levels.ERROR)
    return nil
  end

  M.current_session = {
    handle = handle,
    pid = pid,
    stdin = handle.stdio[1],
    stdout = handle.stdio[2],
    stderr = handle.stdio[3]
  }

  M.setup_output_handlers()

  return M.current_session
end

function M.setup_output_handlers()
  if not M.current_session then return end

  local stdout_buffer = ""
  local stderr_buffer = ""

  M.current_session.stdout:read_start(function(err, data)
    if err then
      vim.notify("Claude Code stdout error: " .. err, vim.log.levels.ERROR)
      return
    end

    if data then
      stdout_buffer = stdout_buffer .. data
      M.process_output(stdout_buffer)
    end
  end)

  M.current_session.stderr:read_start(function(err, data)
    if err then
      vim.notify("Claude Code stderr error: " .. err, vim.log.levels.ERROR)
      return
    end

    if data then
      stderr_buffer = stderr_buffer .. data
      vim.schedule(function()
        vim.notify("Claude Code: " .. data, vim.log.levels.WARN)
      end)
    end
  end)
end

function M.process_output(data)
  vim.schedule(function()
    panel.append_message("claude", data)
    
    -- Check if data contains code changes
    if M.contains_code_changes(data) then
      M.extract_and_store_changes(data)
    end
  end)
end

function M.contains_code_changes(data)
  return data:match("```") or 
         data:match("File:") or 
         data:match("Line %d+") or
         data:match("Lines %d+%-")
end

function M.extract_and_store_changes(data)
  local changes = diff_parser.parse_claude_output(data)
  
  if #changes > 0 then
    M.pending_changes = changes
    vim.notify("Code changes detected. Use :CcDiff to review.", vim.log.levels.INFO)
  end
end

function M.send_message(message)
  if not M.current_session then
    if not M.start_session() then
      return
    end
  end

  local full_message = message .. "\n"
  M.current_session.stdin:write(full_message)

  table.insert(M.message_history, { type = "user", content = message })
  panel.append_message("user", message)
end

function M.send_file(file_path, content)
  local message = string.format("Here's the content of %s:\n\n```\n%s\n```", file_path, content)
  M.send_message(message)
end

function M.send_selection(selection)
  local message = "Here's the selected code:\n\n```\n" .. selection .. "\n```"
  M.send_message(message)
end

function M.apply_changes()
  if #M.pending_changes == 0 then
    vim.notify("No pending changes to apply", vim.log.levels.WARN)
    return
  end

  local diff = require("cc_nvim.diff")
  diff.start_diff_mode(M.pending_changes)
end

function M.get_pending_changes()
  return M.pending_changes
end

function M.clear_pending_changes()
  M.pending_changes = {}
end

function M.apply_file_edit(change)
  local lines = vim.fn.readfile(change.file_path)
  if not lines then
    vim.notify("Could not read file: " .. change.file_path, vim.log.levels.ERROR)
    return
  end

  local buf = vim.fn.bufnr(change.file_path)
  if buf == -1 then
    vim.cmd("edit " .. change.file_path)
    buf = vim.fn.bufnr()
  end

  vim.api.nvim_buf_set_lines(buf, change.start_line - 1, change.end_line, false, change.new_lines)
end

function M.stop_session()
  if M.current_session then
    M.current_session.handle:close()
    M.current_session = nil
  end
end

return M

