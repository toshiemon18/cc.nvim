local M = {}

local config = require("cc_nvim.config")

-- Global state - only one terminal can exist at a time
M.terminal_buf = nil
M.terminal_win = nil
M.job_id = nil
M.is_open = false

-- Lock to prevent concurrent operations
local operation_lock = false

-- Force single instance - kill everything before creating new
function M.force_single_instance()
  -- Find ALL buffers that might be Claude Code terminals
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("Claude Code") then
        -- This is a Claude Code terminal buffer, close all windows showing it
        local wins = vim.fn.win_findbuf(buf)
        for _, win in ipairs(wins) do
          if vim.api.nvim_win_is_valid(win) and vim.fn.winnr('$') > 1 then
            vim.api.nvim_win_close(win, true)
          end
        end
      end
    end
  end
  
  -- Reset our state completely
  M.terminal_buf = nil
  M.terminal_win = nil
  M.job_id = nil
  M.is_open = false
end

function M.get_terminal_state()
  local state = {
    has_valid_buffer = false,
    has_running_job = false,
    has_valid_window = false,
    buffer_windows = {},
    needs_cleanup = false
  }
  
  -- Check buffer validity
  if M.terminal_buf and vim.api.nvim_buf_is_valid(M.terminal_buf) then
    state.has_valid_buffer = true
    -- Find all windows showing this buffer
    state.buffer_windows = vim.fn.win_findbuf(M.terminal_buf)
  end
  
  -- Check job status
  if M.job_id and vim.fn.jobwait({M.job_id}, 0)[1] == -1 then
    state.has_running_job = true
  end
  
  -- Check window validity
  if M.terminal_win and vim.api.nvim_win_is_valid(M.terminal_win) then
    -- Verify window is showing our buffer
    local win_buf = vim.api.nvim_win_get_buf(M.terminal_win)
    if win_buf == M.terminal_buf then
      state.has_valid_window = true
    else
      -- Window exists but showing different buffer
      M.terminal_win = nil
    end
  end
  
  -- Determine if cleanup is needed
  if state.has_valid_buffer and not state.has_running_job then
    state.needs_cleanup = true
  end
  
  return state
end

function M.find_existing_terminal()
  local state = M.get_terminal_state()
  
  -- If cleanup is needed, do it now
  if state.needs_cleanup then
    M.cleanup_terminal()
    return false
  end
  
  -- If we have a valid buffer and running job
  if state.has_valid_buffer and state.has_running_job then
    -- Check if we have a valid window
    if state.has_valid_window then
      return true
    else
      -- Buffer exists but no valid window, need to find or create window
      return "need_window"
    end
  end
  
  return false
end

function M.cleanup_terminal()
  -- Stop the job if it exists
  if M.job_id then
    vim.fn.jobstop(M.job_id)
    M.job_id = nil
  end
  
  -- Close all windows showing the terminal buffer, but don't close the last window
  if M.terminal_buf and vim.api.nvim_buf_is_valid(M.terminal_buf) then
    local wins = vim.fn.win_findbuf(M.terminal_buf)
    local total_windows = vim.fn.winnr('$')
    
    for _, win_id in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win_id) then
        -- Only close if it's not the last window
        if total_windows > 1 then
          vim.api.nvim_win_close(win_id, true)
          total_windows = total_windows - 1
        else
          -- Instead of closing, just switch to a different buffer
          local alt_buf = vim.fn.bufnr('#')
          if alt_buf ~= -1 and alt_buf ~= M.terminal_buf then
            vim.api.nvim_win_set_buf(win_id, alt_buf)
          else
            -- Create a new empty buffer
            local new_buf = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_win_set_buf(win_id, new_buf)
          end
        end
      end
    end
  end
  
  -- Reset all state
  M.terminal_buf = nil
  M.terminal_win = nil
  M.is_open = false
end

function M.auto_repair_state()
  local state = M.get_terminal_state()
  local repaired = false
  
  -- If we have orphaned windows (windows showing our buffer but no job), close them
  if state.has_valid_buffer and not state.has_running_job and #state.buffer_windows > 0 then
    for _, win_id in ipairs(state.buffer_windows) do
      if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
      end
    end
    M.terminal_buf = nil
    M.terminal_win = nil
    M.is_open = false
    repaired = true
  end
  
  -- If we have a job but no valid buffer, stop the job
  if state.has_running_job and not state.has_valid_buffer then
    vim.fn.jobstop(M.job_id)
    M.job_id = nil
    M.is_open = false
    repaired = true
  end
  
  return repaired
end

function M.open_terminal()
  -- Always force single instance to prevent duplicates
  M.force_single_instance()
  
  -- Always create a completely new terminal
  M.create_new_terminal()
end

function M.cleanup_duplicate_windows()
  local state = M.get_terminal_state()
  
  -- If we have multiple windows showing the same buffer, close all but one
  if #state.buffer_windows > 1 then
    -- Keep the first window, close the rest
    for i = 2, #state.buffer_windows do
      local win_id = state.buffer_windows[i]
      if vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
      end
    end
    -- Update our tracked window to the remaining one
    M.terminal_win = state.buffer_windows[1]
  end
end

function M.create_window_for_existing_buffer()
  local panel_config = config.get("panel")
  
  print("DEBUG: create_window_for_existing_buffer() called")
  
  -- Create split window
  if panel_config.position == "right" then
    vim.cmd("rightbelow vsplit")
  elseif panel_config.position == "left" then
    vim.cmd("leftabove vsplit")
  elseif panel_config.position == "bottom" then
    vim.cmd("rightbelow split")
  else
    vim.cmd("leftabove split")
  end

  M.terminal_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.terminal_win, M.terminal_buf)
  
  print("DEBUG: Created window", M.terminal_win, "for existing buffer", M.terminal_buf)
  
  -- Set window size
  M.set_window_size()
  
  -- Setup keymaps
  M.setup_keymaps()
  
  M.is_open = true
  vim.cmd("startinsert")
end

function M.create_window_for_buffer()
  local panel_config = config.get("panel")
  local state = M.get_terminal_state()
  
  -- Clean up any duplicate windows first
  M.cleanup_duplicate_windows()
  
  -- Check if the buffer is already visible in any window after cleanup
  local existing_wins = vim.fn.win_findbuf(M.terminal_buf)
  if #existing_wins > 0 then
    -- Buffer is already visible, just focus the window
    M.terminal_win = existing_wins[1]
    vim.api.nvim_set_current_win(M.terminal_win)
    M.is_open = true
    vim.cmd("startinsert")
    return
  end
  
  -- Create split window only if buffer is not visible
  if panel_config.position == "right" then
    vim.cmd("rightbelow vsplit")
  elseif panel_config.position == "left" then
    vim.cmd("leftabove vsplit")
  elseif panel_config.position == "bottom" then
    vim.cmd("rightbelow split")
  else
    vim.cmd("leftabove split")
  end

  M.terminal_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M.terminal_win, M.terminal_buf)
  
  -- Set window size
  M.set_window_size()
  
  -- Setup keymaps
  M.setup_keymaps()
  
  M.is_open = true
  vim.cmd("startinsert")
end

function M.create_new_terminal()
  local claude_cmd = config.get("claude_executable")
  local panel_config = config.get("panel")
  
  -- Create split window
  if panel_config.position == "right" then
    vim.cmd("rightbelow vsplit")
  elseif panel_config.position == "left" then
    vim.cmd("leftabove vsplit")
  elseif panel_config.position == "bottom" then
    vim.cmd("rightbelow split")
  else
    vim.cmd("leftabove split")
  end

  M.terminal_win = vim.api.nvim_get_current_win()
  
  -- Set window size
  M.set_window_size()

  -- Start Claude Code in terminal
  M.job_id = vim.fn.termopen(claude_cmd, {
    on_exit = function(job_id, code, event)
      M.force_single_instance()
      if code ~= 0 then
        vim.notify("Claude Code exited with code: " .. code, vim.log.levels.WARN)
      end
    end
  })

  if M.job_id == -1 then
    vim.notify("Failed to start Claude Code", vim.log.levels.ERROR)
    return
  end

  M.terminal_buf = vim.api.nvim_get_current_buf()
  M.is_open = true
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(M.terminal_buf, "Claude Code")
  
  -- Setup keymaps
  M.setup_keymaps()
  
  -- Enter terminal mode
  vim.cmd("startinsert")
end

function M.set_window_size()
  local panel_config = config.get("panel")
  
  if panel_config.position == "right" or panel_config.position == "left" then
    local width = math.floor(vim.o.columns * panel_config.size / 100)
    vim.api.nvim_win_set_width(M.terminal_win, width)
  else
    local height = math.floor(vim.o.lines * panel_config.size / 100)
    vim.api.nvim_win_set_height(M.terminal_win, height)
  end
end

function M.setup_keymaps()
  if not M.terminal_buf then return end
  
  local opts = { buffer = M.terminal_buf, silent = true }
  
  -- Exit terminal mode and close
  vim.keymap.set("t", "<C-q>", function() M.close() end, opts)
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
end

function M.close()
  -- Force single instance cleanup
  M.force_single_instance()
end

function M.toggle()
  -- Prevent concurrent operations
  if operation_lock then
    return
  end
  
  operation_lock = true
  
  -- Simple logic: check if ANY Claude Code terminal is visible
  local claude_visible = false
  
  -- Check all windows for Claude Code terminals
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("Claude Code") then
        claude_visible = true
        break
      end
    end
  end
  
  if claude_visible then
    -- Close all Claude Code terminals
    M.force_single_instance()
  else
    -- Open new terminal
    M.open_terminal()
  end
  
  operation_lock = false
end

function M.send_file(file_path, content)
  if not M.is_open or not M.job_id then
    vim.notify("Claude Code terminal is not open", vim.log.levels.WARN)
    return
  end
  
  local message = string.format("Here's the content of %s:\n\n```\n%s\n```\n", file_path, content)
  vim.fn.chansend(M.job_id, message)
end

function M.send_selection(selection)
  if not M.is_open or not M.job_id then
    vim.notify("Claude Code terminal is not open", vim.log.levels.WARN)
    return
  end
  
  local message = string.format("Here's the selected code:\n\n```\n%s\n```\n", selection)
  vim.fn.chansend(M.job_id, message)
end

function M.send_message(message)
  if not M.is_open or not M.job_id then
    vim.notify("Claude Code terminal is not open", vim.log.levels.WARN)
    return
  end
  
  vim.fn.chansend(M.job_id, message .. "\n")
end

function M.is_terminal_open()
  return M.is_open and M.job_id and vim.fn.jobwait({M.job_id}, 0)[1] == -1
end

return M