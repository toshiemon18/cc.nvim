local M = {}

local diff_parser = require("cc_nvim.diff_parser")
local diff_ui = require("cc_nvim.diff_ui")
local config = require("cc_nvim.config")
local git = require("cc_nvim.git")

M.current_session = nil
M.changes = {}
M.current_change_index = 1
M.current_file_index = 1

function M.create_session(changes_data)
  M.current_session = {
    changes = changes_data,
    state = {
      accepted = {},
      rejected = {},
      pending = {},
      current_index = 1,
      current_file_index = 1
    },
    ui = nil
  }
  
  M.changes = changes_data
  M.current_change_index = 1
  M.current_file_index = 1
  
  return M.current_session
end

function M.start_diff_mode(changes_data)
  if not changes_data or #changes_data == 0 then
    vim.notify("No changes to review", vim.log.levels.WARN)
    return
  end
  
  M.create_session(changes_data)
  diff_ui.open(M.current_session)
end

function M.start_git_diff_mode(commit_or_branch)
  if not git.is_git_repository() then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end
  
  local diff_output, error_msg = git.get_git_diff(commit_or_branch)
  
  if not diff_output then
    vim.notify(error_msg or "No differences found", vim.log.levels.WARN)
    return
  end
  
  local title = M.create_git_diff_title(commit_or_branch)
  local changes = git.create_git_diff_changes(diff_output, title)
  
  if #changes == 0 then
    vim.notify("No changes to display", vim.log.levels.WARN)
    return
  end
  
  M.create_session(changes)
  M.current_session.source = "git"
  M.current_session.readonly = true
  M.current_session.title = title
  
  diff_ui.open(M.current_session)
end

function M.create_git_diff_title(commit_or_branch)
  if not commit_or_branch or commit_or_branch == "" then
    return "Git Diff (Unstaged Changes)"
  elseif commit_or_branch:match("^%w+%.%.%w+$") then
    return string.format("Git Diff (%s)", commit_or_branch)
  elseif commit_or_branch:match("^%w+%.%.%.%w+$") then
    return string.format("Git Diff (%s)", commit_or_branch)
  else
    local commit_info, err = git.get_commit_info(commit_or_branch)
    if commit_info then
      return string.format("Git Diff (%s: %s)", commit_or_branch, commit_info.subject)
    else
      return string.format("Git Diff (%s)", commit_or_branch)
    end
  end
end

function M.get_current_change()
  if not M.current_session or not M.current_session.changes then
    return nil
  end
  
  local file_changes = M.current_session.changes[M.current_file_index]
  if not file_changes or not file_changes.changes then
    return nil
  end
  
  return file_changes.changes[M.current_change_index]
end

function M.get_current_file()
  if not M.current_session or not M.current_session.changes then
    return nil
  end
  
  return M.current_session.changes[M.current_file_index]
end

function M.next_change()
  if not M.current_session then return end
  
  local current_file = M.get_current_file()
  if not current_file then return end
  
  if M.current_change_index < #current_file.changes then
    M.current_change_index = M.current_change_index + 1
  else
    M.next_file()
  end
  
  diff_ui.refresh()
end

function M.prev_change()
  if not M.current_session then return end
  
  if M.current_change_index > 1 then
    M.current_change_index = M.current_change_index - 1
  else
    M.prev_file()
  end
  
  diff_ui.refresh()
end

function M.next_file()
  if not M.current_session then return end
  
  if M.current_file_index < #M.current_session.changes then
    M.current_file_index = M.current_file_index + 1
    M.current_change_index = 1
  end
  
  diff_ui.refresh()
end

function M.prev_file()
  if not M.current_session then return end
  
  if M.current_file_index > 1 then
    M.current_file_index = M.current_file_index - 1
    local current_file = M.get_current_file()
    if current_file then
      M.current_change_index = #current_file.changes
    end
  end
  
  diff_ui.refresh()
end

function M.accept_change()
  local change = M.get_current_change()
  if not change then return end
  
  local key = M.current_file_index .. ":" .. M.current_change_index
  M.current_session.state.accepted[key] = change
  M.current_session.state.rejected[key] = nil
  M.current_session.state.pending[key] = nil
  
  change.status = "accepted"
  M.next_change()
  
  vim.notify("Change accepted", vim.log.levels.INFO)
end

function M.reject_change()
  local change = M.get_current_change()
  if not change then return end
  
  local key = M.current_file_index .. ":" .. M.current_change_index
  M.current_session.state.rejected[key] = change
  M.current_session.state.accepted[key] = nil
  M.current_session.state.pending[key] = nil
  
  change.status = "rejected"
  M.next_change()
  
  vim.notify("Change rejected", vim.log.levels.INFO)
end

function M.skip_change()
  local change = M.get_current_change()
  if not change then return end
  
  local key = M.current_file_index .. ":" .. M.current_change_index
  M.current_session.state.pending[key] = change
  M.current_session.state.accepted[key] = nil
  M.current_session.state.rejected[key] = nil
  
  change.status = "pending"
  M.next_change()
  
  vim.notify("Change skipped", vim.log.levels.INFO)
end

function M.accept_all()
  if not M.current_session then return end
  
  for file_idx, file_data in ipairs(M.current_session.changes) do
    for change_idx, change in ipairs(file_data.changes) do
      local key = file_idx .. ":" .. change_idx
      M.current_session.state.accepted[key] = change
      M.current_session.state.rejected[key] = nil
      M.current_session.state.pending[key] = nil
      change.status = "accepted"
    end
  end
  
  diff_ui.refresh()
  vim.notify("All changes accepted", vim.log.levels.INFO)
end

function M.reject_all()
  if not M.current_session then return end
  
  for file_idx, file_data in ipairs(M.current_session.changes) do
    for change_idx, change in ipairs(file_data.changes) do
      local key = file_idx .. ":" .. change_idx
      M.current_session.state.rejected[key] = change
      M.current_session.state.accepted[key] = nil
      M.current_session.state.pending[key] = nil
      change.status = "rejected"
    end
  end
  
  diff_ui.refresh()
  vim.notify("All changes rejected", vim.log.levels.INFO)
end

function M.accept_current_file()
  if not M.current_session then return end
  
  local current_file = M.get_current_file()
  if not current_file then return end
  
  for change_idx, change in ipairs(current_file.changes) do
    local key = M.current_file_index .. ":" .. change_idx
    M.current_session.state.accepted[key] = change
    M.current_session.state.rejected[key] = nil
    M.current_session.state.pending[key] = nil
    change.status = "accepted"
  end
  
  diff_ui.refresh()
  vim.notify("All changes in current file accepted", vim.log.levels.INFO)
end

function M.reject_current_file()
  if not M.current_session then return end
  
  local current_file = M.get_current_file()
  if not current_file then return end
  
  for change_idx, change in ipairs(current_file.changes) do
    local key = M.current_file_index .. ":" .. change_idx
    M.current_session.state.rejected[key] = change
    M.current_session.state.accepted[key] = nil
    M.current_session.state.pending[key] = nil
    change.status = "rejected"
  end
  
  diff_ui.refresh()
  vim.notify("All changes in current file rejected", vim.log.levels.INFO)
end

function M.apply_changes()
  if not M.current_session then return end
  
  if M.current_session.readonly then
    vim.notify("Cannot apply changes: read-only diff mode", vim.log.levels.WARN)
    return
  end
  
  local accepted_count = 0
  local failed_count = 0
  
  for file_idx, file_data in ipairs(M.current_session.changes) do
    for change_idx, change in ipairs(file_data.changes) do
      local key = file_idx .. ":" .. change_idx
      if M.current_session.state.accepted[key] then
        local success = M.apply_single_change(file_data.file_path, change)
        if success then
          accepted_count = accepted_count + 1
        else
          failed_count = failed_count + 1
        end
      end
    end
  end
  
  if accepted_count > 0 then
    vim.notify(string.format("Applied %d changes successfully", accepted_count), vim.log.levels.INFO)
  end
  
  if failed_count > 0 then
    vim.notify(string.format("Failed to apply %d changes", failed_count), vim.log.levels.ERROR)
  end
  
  M.close_diff_mode()
end

function M.apply_single_change(file_path, change)
  local success, lines = pcall(vim.fn.readfile, file_path)
  if not success then
    return false
  end
  
  local start_line = change.start_line
  local end_line = change.end_line or start_line
  
  local new_lines = change.new_lines or {}
  
  for i = 1, #new_lines do
    lines[start_line + i - 1] = new_lines[i]
  end
  
  if end_line > start_line then
    for i = start_line + #new_lines, end_line do
      table.remove(lines, start_line + #new_lines)
    end
  end
  
  local write_success = pcall(vim.fn.writefile, lines, file_path)
  if not write_success then
    return false
  end
  
  local buf = vim.fn.bufnr(file_path)
  if buf ~= -1 then
    vim.api.nvim_buf_set_lines(buf, start_line - 1, end_line, false, new_lines)
  end
  
  return true
end

function M.close_diff_mode()
  if M.current_session then
    diff_ui.close()
    M.current_session = nil
  end
end

function M.toggle_display_mode()
  diff_ui.toggle_display_mode()
end

function M.get_stats()
  if not M.current_session then
    return { total = 0, accepted = 0, rejected = 0, pending = 0 }
  end
  
  local total = 0
  local accepted = 0
  local rejected = 0
  local pending = 0
  
  for file_idx, file_data in ipairs(M.current_session.changes) do
    for change_idx, change in ipairs(file_data.changes) do
      total = total + 1
      local key = file_idx .. ":" .. change_idx
      
      if M.current_session.state.accepted[key] then
        accepted = accepted + 1
      elseif M.current_session.state.rejected[key] then
        rejected = rejected + 1
      else
        pending = pending + 1
      end
    end
  end
  
  return {
    total = total,
    accepted = accepted,
    rejected = rejected,
    pending = pending,
    current_file = M.current_file_index,
    total_files = #M.current_session.changes,
    current_change = M.current_change_index
  }
end

return M