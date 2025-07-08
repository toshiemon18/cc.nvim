local M = {}

local diff_parser = require("cc_nvim.diff_parser")
local utils = require("cc_nvim.utils")

function M.get_git_diff(commit_or_branch)
  local cmd
  
  if not commit_or_branch or commit_or_branch == "" then
    -- Show unstaged changes
    cmd = "git diff"
  elseif commit_or_branch:match("^%w+%.%.%w+$") then
    -- Range format: commit1..commit2
    cmd = string.format("git diff %s", commit_or_branch)
  elseif commit_or_branch:match("^%w+%.%.%.%w+$") then
    -- Range format: commit1...commit2 (three dots)
    cmd = string.format("git diff %s", commit_or_branch)
  else
    -- Single commit or branch
    cmd = string.format("git diff %s", commit_or_branch)
  end
  
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return nil, "Failed to execute git diff command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git diff failed: " .. (output or "Unknown error")
  end
  
  if output == "" then
    return nil, "No differences found"
  end
  
  return output, nil
end

function M.get_staged_diff()
  local cmd = "git diff --staged"
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return nil, "Failed to execute git diff --staged command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git diff --staged failed: " .. (output or "Unknown error")
  end
  
  if output == "" then
    return nil, "No staged changes found"
  end
  
  return output, nil
end

function M.get_commit_diff(commit_hash)
  local cmd = string.format("git show %s", commit_hash)
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return nil, "Failed to execute git show command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git show failed: " .. (output or "Unknown error")
  end
  
  return output, nil
end

function M.get_branch_diff(branch_name, base_branch)
  base_branch = base_branch or "HEAD"
  local cmd = string.format("git diff %s..%s", base_branch, branch_name)
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return nil, "Failed to execute git diff command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git diff failed: " .. (output or "Unknown error")
  end
  
  if output == "" then
    return nil, "No differences found between branches"
  end
  
  return output, nil
end

function M.get_working_tree_status()
  local cmd = "git status --porcelain"
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return nil, "Failed to execute git status command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git status failed: " .. (output or "Unknown error")
  end
  
  return M.parse_git_status(output), nil
end

function M.parse_git_status(status_output)
  local files = {}
  
  for line in status_output:gmatch("[^\r\n]+") do
    if line:match("^%s*$") then
      goto continue
    end
    
    local status_code = line:sub(1, 2)
    local file_path = line:sub(4)
    
    local file_info = {
      path = file_path,
      status = status_code,
      staged = status_code:sub(1, 1) ~= " " and status_code:sub(1, 1) ~= "?",
      unstaged = status_code:sub(2, 2) ~= " ",
      untracked = status_code:sub(1, 1) == "?"
    }
    
    table.insert(files, file_info)
    ::continue::
  end
  
  return files
end

function M.get_file_diff(file_path, commit_or_branch)
  local cmd
  
  if not commit_or_branch or commit_or_branch == "" then
    cmd = string.format("git diff -- %s", file_path)
  else
    cmd = string.format("git diff %s -- %s", commit_or_branch, file_path)
  end
  
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    return nil, "Failed to execute git diff command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git diff failed: " .. (output or "Unknown error")
  end
  
  if output == "" then
    return nil, "No differences found for file"
  end
  
  return output, nil
end

function M.is_git_repository()
  local cmd = "git rev-parse --is-inside-work-tree"
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return false
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  return success and exit_code == 0 and output:match("true")
end

function M.get_current_branch()
  local cmd = "git branch --show-current"
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return nil
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if success and exit_code == 0 then
    return output:gsub("%s+", "")
  end
  
  return nil
end

function M.get_commit_info(commit_hash)
  local cmd = string.format("git log -1 --format='%%H|%%s|%%an|%%ad' %s", commit_hash)
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return nil, "Failed to execute git log command"
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  if not success or exit_code ~= 0 then
    return nil, "Git log failed: " .. (output or "Unknown error")
  end
  
  local hash, subject, author, date = output:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
  
  if hash then
    return {
      hash = hash,
      subject = subject,
      author = author,
      date = date
    }, nil
  end
  
  return nil, "Failed to parse commit info"
end

function M.validate_commit_or_branch(ref)
  if not ref or ref == "" then
    return true -- Empty is valid (means unstaged)
  end
  
  local cmd = string.format("git rev-parse --verify %s", ref)
  local handle = io.popen(cmd .. " 2>&1")
  
  if not handle then
    return false
  end
  
  local output = handle:read("*all")
  local success, exit_type, exit_code = handle:close()
  
  return success and exit_code == 0
end

function M.get_diff_summary(diff_output)
  local files_changed = 0
  local lines_added = 0
  local lines_deleted = 0
  
  for line in diff_output:gmatch("[^\r\n]+") do
    if line:match("^diff --git") then
      files_changed = files_changed + 1
    elseif line:match("^%+") and not line:match("^%+%+%+") then
      lines_added = lines_added + 1
    elseif line:match("^%-") and not line:match("^%-%-%-") then
      lines_deleted = lines_deleted + 1
    end
  end
  
  return {
    files_changed = files_changed,
    lines_added = lines_added,
    lines_deleted = lines_deleted
  }
end

function M.create_git_diff_changes(diff_output, title)
  local changes = diff_parser.parse_git_diff(diff_output)
  
  -- Add metadata
  for _, file_change in ipairs(changes) do
    file_change.source = "git"
    file_change.title = title or "Git Diff"
    file_change.readonly = true -- Git diffs are read-only by default
  end
  
  return changes
end

return M