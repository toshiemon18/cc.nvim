local M = {}

local config = require("cc_nvim.config")
local diff_parser = require("cc_nvim.diff.parser")

M.buf = nil
M.win = nil
M.is_open = false
M.display_mode = "side_by_side"
M.context_lines = 3
M.current_session = nil

function M.open(session)
  if M.is_open then
    return
  end
  
  M.current_session = session
  M.create_buffer()
  M.create_window()
  M.setup_keymaps()
  M.setup_highlights()
  M.refresh()
  
  M.is_open = true
end

function M.create_buffer()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    return M.buf
  end
  
  M.buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_option(M.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.buf, "swapfile", false)
  vim.api.nvim_buf_set_option(M.buf, "filetype", "cc_nvim_diff")
  vim.api.nvim_buf_set_name(M.buf, "Claude Code Diff")
  
  return M.buf
end

function M.create_window()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local title = "Claude Code Diff Review"
  if M.current_session and M.current_session.title then
    title = M.current_session.title
  end
  
  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center"
  }
  
  M.win = vim.api.nvim_open_win(M.buf, true, win_config)
  
  vim.api.nvim_win_set_option(M.win, "wrap", false)
  vim.api.nvim_win_set_option(M.win, "number", true)
  vim.api.nvim_win_set_option(M.win, "relativenumber", false)
  vim.api.nvim_win_set_option(M.win, "signcolumn", "no")
  vim.api.nvim_win_set_option(M.win, "cursorline", true)
end

function M.setup_keymaps()
  if not M.buf then return end
  
  local opts = { buffer = M.buf, silent = true }
  local diff = require("cc_nvim.diff")
  
  vim.keymap.set("n", "j", diff.next_change, opts)
  vim.keymap.set("n", "k", diff.prev_change, opts)
  vim.keymap.set("n", "l", diff.next_file, opts)
  vim.keymap.set("n", "h", diff.prev_file, opts)
  
  vim.keymap.set("n", "<Space>", diff.accept_change, opts)
  vim.keymap.set("n", "<Enter>", diff.accept_change, opts)
  vim.keymap.set("n", "x", diff.reject_change, opts)
  vim.keymap.set("n", "d", diff.reject_change, opts)
  vim.keymap.set("n", "s", diff.skip_change, opts)
  
  vim.keymap.set("n", "a", diff.accept_all, opts)
  vim.keymap.set("n", "r", diff.reject_all, opts)
  vim.keymap.set("n", "A", diff.accept_current_file, opts)
  vim.keymap.set("n", "R", diff.reject_current_file, opts)
  
  vim.keymap.set("n", "m", function() M.toggle_display_mode() end, opts)
  vim.keymap.set("n", "c", function() M.toggle_context() end, opts)
  vim.keymap.set("n", "+", function() M.increase_context() end, opts)
  vim.keymap.set("n", "-", function() M.decrease_context() end, opts)
  
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", "?", function() M.show_help() end, opts)
  
  vim.keymap.set("n", "<C-a>", diff.apply_changes, opts)
  if not M.current_session or not M.current_session.readonly then
    vim.keymap.set("n", "<Enter>", diff.apply_changes, opts)
  end
end

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "CcNvimDiffAdd", { fg = "#00ff00", bg = "#004400" })
  vim.api.nvim_set_hl(0, "CcNvimDiffRemove", { fg = "#ff0000", bg = "#440000" })
  vim.api.nvim_set_hl(0, "CcNvimDiffChange", { fg = "#ffff00", bg = "#444400" })
  vim.api.nvim_set_hl(0, "CcNvimDiffAccepted", { fg = "#00ff00", bold = true })
  vim.api.nvim_set_hl(0, "CcNvimDiffRejected", { fg = "#ff0000", bold = true })
  vim.api.nvim_set_hl(0, "CcNvimDiffPending", { fg = "#ffff00", bold = true })
  vim.api.nvim_set_hl(0, "CcNvimDiffHeader", { fg = "#00ffff", bold = true })
  vim.api.nvim_set_hl(0, "CcNvimDiffSeparator", { fg = "#888888" })
end

function M.refresh()
  if not M.buf or not M.current_session then return end
  
  local lines = {}
  local highlights = {}
  
  M.render_header(lines, highlights)
  M.render_stats(lines, highlights)
  M.render_current_change(lines, highlights)
  M.render_footer(lines, highlights)
  
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  
  M.apply_highlights(highlights)
end

function M.render_header(lines, highlights)
  local diff = require("cc_nvim.diff")
  local current_file = diff.get_current_file()
  
  if current_file then
    local header = string.format("File: %s", current_file.file_path)
    table.insert(lines, header)
    table.insert(highlights, {
      line = #lines - 1,
      col_start = 0,
      col_end = #header,
      hl_group = "CcNvimDiffHeader"
    })
  end
  
  local separator = string.rep("─", vim.api.nvim_win_get_width(M.win or 0) - 2)
  table.insert(lines, separator)
  table.insert(highlights, {
    line = #lines - 1,
    col_start = 0,
    col_end = #separator,
    hl_group = "CcNvimDiffSeparator"
  })
end

function M.render_stats(lines, highlights)
  local diff = require("cc_nvim.diff")
  local stats = diff.get_stats()
  
  local stats_line = string.format(
    "Changes: %d/%d | Files: %d/%d | Accepted: %d | Rejected: %d | Pending: %d",
    stats.current_change,
    stats.total,
    stats.current_file,
    stats.total_files,
    stats.accepted,
    stats.rejected,
    stats.pending
  )
  
  table.insert(lines, stats_line)
  table.insert(lines, "")
end

function M.render_current_change(lines, highlights)
  local diff = require("cc_nvim.diff")
  local current_change = diff.get_current_change()
  local current_file = diff.get_current_file()
  
  if not current_change or not current_file then
    table.insert(lines, "No changes to display")
    return
  end
  
  if M.display_mode == "side_by_side" then
    M.render_side_by_side(lines, highlights, current_file, current_change)
  elseif M.display_mode == "inline" then
    M.render_inline(lines, highlights, current_file, current_change)
  else
    M.render_unified(lines, highlights, current_file, current_change)
  end
end

function M.render_side_by_side(lines, highlights, file_data, change)
  local context_lines = diff_parser.get_context_lines(
    file_data.file_path,
    change.start_line,
    change.end_line,
    M.context_lines
  )
  
  local win_width = vim.api.nvim_win_get_width(M.win or 0)
  local col_width = math.floor((win_width - 3) / 2)
  
  table.insert(lines, string.format("%-" .. col_width .. "s │ %s", "Before", "After"))
  table.insert(lines, string.rep("─", col_width) .. "─┼─" .. string.rep("─", col_width))
  
  local old_lines = change.old_lines or {}
  local new_lines = change.new_lines or {}
  local max_lines = math.max(#old_lines, #new_lines)
  
  for i = 1, max_lines do
    local old_line = old_lines[i] or ""
    local new_line = new_lines[i] or ""
    
    local old_display = string.format("%-" .. col_width .. "s", old_line:sub(1, col_width))
    local new_display = string.format("%-" .. col_width .. "s", new_line:sub(1, col_width))
    
    local line_content = old_display .. " │ " .. new_display
    table.insert(lines, line_content)
    
    if old_line ~= new_line then
      if old_line ~= "" then
        table.insert(highlights, {
          line = #lines - 1,
          col_start = 0,
          col_end = col_width,
          hl_group = "CcNvimDiffRemove"
        })
      end
      
      if new_line ~= "" then
        table.insert(highlights, {
          line = #lines - 1,
          col_start = col_width + 3,
          col_end = col_width + 3 + #new_display,
          hl_group = "CcNvimDiffAdd"
        })
      end
    end
  end
end

function M.render_inline(lines, highlights, file_data, change)
  local old_lines = change.old_lines or {}
  local new_lines = change.new_lines or {}
  
  table.insert(lines, string.format("@@ -%d,%d +%d,%d @@", 
    change.start_line, #old_lines, change.start_line, #new_lines))
  
  for _, line in ipairs(old_lines) do
    local content = "-" .. line
    table.insert(lines, content)
    table.insert(highlights, {
      line = #lines - 1,
      col_start = 0,
      col_end = #content,
      hl_group = "CcNvimDiffRemove"
    })
  end
  
  for _, line in ipairs(new_lines) do
    local content = "+" .. line
    table.insert(lines, content)
    table.insert(highlights, {
      line = #lines - 1,
      col_start = 0,
      col_end = #content,
      hl_group = "CcNvimDiffAdd"
    })
  end
end

function M.render_unified(lines, highlights, file_data, change)
  table.insert(lines, "Before:")
  for _, line in ipairs(change.old_lines or {}) do
    table.insert(lines, "  " .. line)
  end
  
  table.insert(lines, "")
  table.insert(lines, "After:")
  for _, line in ipairs(change.new_lines or {}) do
    table.insert(lines, "  " .. line)
  end
end

function M.render_footer(lines, highlights)
  table.insert(lines, "")
  local separator = string.rep("─", vim.api.nvim_win_get_width(M.win or 0) - 2)
  table.insert(lines, separator)
  
  local diff = require("cc_nvim.diff")
  local current_change = diff.get_current_change()
  
  if current_change then
    local status_text = "Status: "
    if current_change.status == "accepted" then
      status_text = status_text .. "✓ ACCEPTED"
    elseif current_change.status == "rejected" then
      status_text = status_text .. "✗ REJECTED"
    else
      status_text = status_text .. "○ PENDING"
    end
    
    table.insert(lines, status_text)
  end
  
  table.insert(lines, "")
  
  if M.current_session and M.current_session.readonly then
    table.insert(lines, "Controls: [j/k] Navigate [h/l] Files [m] Display Mode [q] Quit [?] Help (Read-only)")
  else
    table.insert(lines, "Controls: [Space] Accept [x] Reject [s] Skip [a] Accept All [r] Reject All [Enter] Apply [q] Quit [?] Help")
  end
end

function M.apply_highlights(highlights)
  if not M.buf then return end
  
  local ns_id = vim.api.nvim_create_namespace("cc_nvim_diff")
  vim.api.nvim_buf_clear_namespace(M.buf, ns_id, 0, -1)
  
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      M.buf,
      ns_id,
      hl.hl_group,
      hl.line,
      hl.col_start,
      hl.col_end
    )
  end
end

function M.toggle_display_mode()
  if M.display_mode == "side_by_side" then
    M.display_mode = "inline"
  elseif M.display_mode == "inline" then
    M.display_mode = "unified"
  else
    M.display_mode = "side_by_side"
  end
  
  M.refresh()
  vim.notify("Display mode: " .. M.display_mode, vim.log.levels.INFO)
end

function M.toggle_context()
  M.context_lines = M.context_lines == 3 and 0 or 3
  M.refresh()
  vim.notify("Context lines: " .. M.context_lines, vim.log.levels.INFO)
end

function M.increase_context()
  M.context_lines = math.min(M.context_lines + 1, 10)
  M.refresh()
  vim.notify("Context lines: " .. M.context_lines, vim.log.levels.INFO)
end

function M.decrease_context()
  M.context_lines = math.max(M.context_lines - 1, 0)
  M.refresh()
  vim.notify("Context lines: " .. M.context_lines, vim.log.levels.INFO)
end

function M.show_help()
  local help_lines = {
    "Claude Code Diff Review - Help",
    "",
    "Navigation:",
    "  j/k     - Next/Previous change",
    "  h/l     - Previous/Next file",
    "",
    "Actions:",
    "  Space   - Accept change",
    "  x/d     - Reject change",
    "  s       - Skip change",
    "  a       - Accept all changes",
    "  r       - Reject all changes",
    "  A       - Accept all changes in current file",
    "  R       - Reject all changes in current file",
    "",
    "View:",
    "  m       - Toggle display mode",
    "  c       - Toggle context lines",
    "  +/-     - Increase/Decrease context",
    "",
    "Other:",
    "  Enter   - Apply accepted changes",
    "  q/Esc   - Quit",
    "  ?       - Show this help",
    "",
    "Press any key to continue..."
  }
  
  local help_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, help_lines)
  
  local width = 50
  local height = #help_lines
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local help_win = vim.api.nvim_open_win(help_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = "Help"
  })
  
  vim.keymap.set("n", "<any>", function()
    vim.api.nvim_win_close(help_win, true)
  end, { buffer = help_buf })
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  
  M.win = nil
  M.is_open = false
  M.current_session = nil
end

return M