local M = {}

function M.parse_claude_output(output)
  local changes = {}
  local current_file = nil
  local current_change = nil
  local in_code_block = false
  local code_block_type = nil
  
  local lines = vim.split(output, "\n")
  
  for i, line in ipairs(lines) do
    if line:match("^```") then
      if not in_code_block then
        in_code_block = true
        code_block_type = line:match("^```(%w*)")
        
        if current_file and current_change then
          current_change.new_lines = {}
        end
      else
        in_code_block = false
        code_block_type = nil
        
        if current_file and current_change then
          table.insert(current_file.changes, current_change)
          current_change = nil
        end
      end
    elseif in_code_block and current_change then
      table.insert(current_change.new_lines, line)
    elseif line:match("^%s*File:%s*(.+)") or line:match("^%s*(.+%.%w+)%s*$") then
      local file_path = line:match("^%s*File:%s*(.+)") or line:match("^%s*(.+%.%w+)%s*$")
      file_path = file_path:gsub("^%s*", ""):gsub("%s*$", "")
      
      if current_file and #current_file.changes > 0 then
        table.insert(changes, current_file)
      end
      
      current_file = {
        file_path = file_path,
        changes = {}
      }
    elseif line:match("^%s*Line%s*(%d+)") or line:match("^%s*Lines%s*(%d+)%-(%d+)") then
      local start_line, end_line = line:match("^%s*Lines%s*(%d+)%-(%d+)")
      if not start_line then
        start_line = line:match("^%s*Line%s*(%d+)")
        end_line = start_line
      end
      
      if current_file and start_line then
        current_change = {
          start_line = tonumber(start_line),
          end_line = tonumber(end_line),
          new_lines = {},
          description = "",
          status = "pending"
        }
      end
    end
  end
  
  if current_file and current_change then
    table.insert(current_file.changes, current_change)
  end
  
  if current_file and #current_file.changes > 0 then
    table.insert(changes, current_file)
  end
  
  return M.validate_changes(changes)
end

function M.parse_git_diff(diff_output)
  local changes = {}
  local current_file = nil
  local current_change = nil
  local hunk_header = nil
  local in_hunk = false
  
  local lines = vim.split(diff_output, "\n")
  
  for i, line in ipairs(lines) do
    if line:match("^diff %-%-git") then
      -- Save previous file if exists
      if current_file and #current_file.changes > 0 then
        table.insert(changes, current_file)
      end
      
      -- Start new file
      current_file = {
        file_path = "",
        changes = {}
      }
      current_change = nil
      in_hunk = false
      
    elseif line:match("^%-%-%- a/(.+)") then
      -- Old file path (usually same as new file path)
      -- We'll use the +++ line for the actual path
      
    elseif line:match("^%+%+%+ b/(.+)") then
      if current_file then
        current_file.file_path = line:match("^%+%+%+ b/(.+)")
      end
      
    elseif line:match("^%+%+%+ /dev/null") then
      -- New file being created
      if current_file then
        current_file.file_path = current_file.file_path or "new_file"
      end
      
    elseif line:match("^@@") then
      -- Hunk header: @@ -old_start,old_count +new_start,new_count @@
      local old_start, old_count, new_start, new_count = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
      
      if current_file and old_start and new_start then
        -- Save previous change if exists
        if current_change then
          table.insert(current_file.changes, current_change)
        end
        
        -- Parse counts (default to 1 if not specified)
        old_count = old_count ~= "" and tonumber(old_count) or 1
        new_count = new_count ~= "" and tonumber(new_count) or 1
        
        current_change = {
          start_line = tonumber(new_start),
          end_line = tonumber(new_start) + new_count - 1,
          old_start = tonumber(old_start),
          old_end = tonumber(old_start) + old_count - 1,
          old_lines = {},
          new_lines = {},
          description = line,
          status = "pending",
          hunk_header = line
        }
        
        in_hunk = true
      end
      
    elseif in_hunk and current_change then
      if line:match("^%+") and not line:match("^%+%+%+") then
        -- Added line
        table.insert(current_change.new_lines, line:sub(2))
        
      elseif line:match("^%-") and not line:match("^%-%-%-") then
        -- Removed line
        table.insert(current_change.old_lines, line:sub(2))
        
      elseif line:match("^%s") then
        -- Context line (unchanged)
        table.insert(current_change.new_lines, line:sub(2))
        table.insert(current_change.old_lines, line:sub(2))
        
      elseif line:match("^\\") then
        -- "\ No newline at end of file" - ignore
        
      else
        -- End of hunk
        in_hunk = false
      end
    end
  end
  
  -- Save last change and file
  if current_file and current_change then
    table.insert(current_file.changes, current_change)
  end
  
  if current_file and #current_file.changes > 0 then
    table.insert(changes, current_file)
  end
  
  return M.validate_changes(changes)
end

function M.create_manual_change(file_path, start_line, end_line, old_lines, new_lines)
  return {
    file_path = file_path,
    changes = {
      {
        start_line = start_line,
        end_line = end_line,
        old_lines = old_lines,
        new_lines = new_lines,
        description = string.format("Manual change at lines %d-%d", start_line, end_line),
        status = "pending"
      }
    }
  }
end

function M.validate_changes(changes)
  local validated = {}
  
  for _, file_data in ipairs(changes) do
    if file_data.file_path and file_data.file_path ~= "" then
      local validated_file = {
        file_path = file_data.file_path,
        changes = {}
      }
      
      for _, change in ipairs(file_data.changes) do
        if change.start_line and change.start_line > 0 then
          local validated_change = {
            start_line = change.start_line,
            end_line = change.end_line or change.start_line,
            old_lines = change.old_lines or {},
            new_lines = change.new_lines or {},
            description = change.description or "",
            status = change.status or "pending"
          }
          
          table.insert(validated_file.changes, validated_change)
        end
      end
      
      if #validated_file.changes > 0 then
        table.insert(validated, validated_file)
      end
    end
  end
  
  return validated
end

function M.get_file_content(file_path)
  local success, lines = pcall(vim.fn.readfile, file_path)
  if success then
    return lines
  else
    return {}
  end
end

function M.get_context_lines(file_path, start_line, end_line, context_size)
  context_size = context_size or 3
  
  local lines = M.get_file_content(file_path)
  local context_start = math.max(1, start_line - context_size)
  local context_end = math.min(#lines, end_line + context_size)
  
  local context_lines = {}
  for i = context_start, context_end do
    table.insert(context_lines, {
      line_number = i,
      content = lines[i] or "",
      is_changed = i >= start_line and i <= end_line
    })
  end
  
  return context_lines
end

function M.format_change_summary(change)
  local old_count = #change.old_lines
  local new_count = #change.new_lines
  
  if old_count == 0 and new_count > 0 then
    return string.format("Added %d lines", new_count)
  elseif old_count > 0 and new_count == 0 then
    return string.format("Removed %d lines", old_count)
  elseif old_count == new_count then
    return string.format("Modified %d lines", old_count)
  else
    return string.format("Changed %d lines to %d lines", old_count, new_count)
  end
end

function M.calculate_change_stats(changes)
  local stats = {
    total_files = #changes,
    total_changes = 0,
    lines_added = 0,
    lines_removed = 0,
    lines_modified = 0
  }
  
  for _, file_data in ipairs(changes) do
    stats.total_changes = stats.total_changes + #file_data.changes
    
    for _, change in ipairs(file_data.changes) do
      local old_count = #change.old_lines
      local new_count = #change.new_lines
      
      if old_count == 0 then
        stats.lines_added = stats.lines_added + new_count
      elseif new_count == 0 then
        stats.lines_removed = stats.lines_removed + old_count
      else
        stats.lines_modified = stats.lines_modified + math.max(old_count, new_count)
      end
    end
  end
  
  return stats
end

return M