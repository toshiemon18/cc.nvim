local M = {}

local config = require("cc_nvim.config")

M.buf = nil
M.win = nil
M.is_open = false

function M.setup()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.close()
    end,
  })
end

function M.create_buffer()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    return M.buf
  end

  M.buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(M.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.buf, "swapfile", false)
  vim.api.nvim_buf_set_option(M.buf, "filetype", "cc_nvim")
  vim.api.nvim_buf_set_name(M.buf, "Claude Code")

  M.setup_buffer_keymaps()
  M.setup_highlights()

  return M.buf
end

function M.setup_buffer_keymaps()
  local opts = { buffer = M.buf, silent = true }

  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", "<CR>", function() M.send_input() end, opts)
  vim.keymap.set("i", "<C-CR>", function() M.send_input() end, opts)
end

function M.setup_highlights()
  local highlights = config.get("highlights")

  for name, group in pairs(highlights) do
    vim.api.nvim_set_hl(0, "CcNvim" .. name:gsub("_", ""), { link = group })
  end
end

function M.open()
  if M.is_open then
    return
  end

  M.create_buffer()

  local panel_config = config.get("panel")
  local width = math.floor(vim.o.columns * panel_config.size / 100)
  local height = vim.o.lines - 2

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = vim.o.columns - width,
    row = 0,
    style = "minimal",
    border = panel_config.border,
  }

  M.win = vim.api.nvim_open_win(M.buf, true, win_config)

  vim.api.nvim_win_set_option(M.win, "wrap", true)
  vim.api.nvim_win_set_option(M.win, "number", false)
  vim.api.nvim_win_set_option(M.win, "relativenumber", false)
  vim.api.nvim_win_set_option(M.win, "signcolumn", "no")

  M.is_open = true
  M.append_message("system", "Claude Code panel opened. Type your message and press Enter.")
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end

  M.win = nil
  M.is_open = false
end

function M.toggle()
  if M.is_open then
    M.close()
  else
    M.open()
  end
end

function M.append_message(sender, content)
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
    return
  end

  local timestamp = os.date("%H:%M:%S")
  local prefix = string.format("[%s] %s: ", timestamp, sender)
  local lines = vim.split(content, "\n")

  lines[1] = prefix .. lines[1]

  for i = 2, #lines do
    lines[i] = string.rep(" ", #prefix) .. lines[i]
  end

  local line_count = vim.api.nvim_buf_line_count(M.buf)
  vim.api.nvim_buf_set_lines(M.buf, line_count, line_count, false, lines)
  vim.api.nvim_buf_set_lines(M.buf, line_count + #lines, line_count + #lines, false, { "" })

  M.highlight_message(line_count, #lines, sender)
  M.scroll_to_bottom()
end

function M.highlight_message(start_line, line_count, sender)
  local ns_id = vim.api.nvim_create_namespace("cc_nvim")
  local hl_group = "CcNvim" .. sender:gsub("_", "")

  for i = 0, line_count - 1 do
    vim.api.nvim_buf_add_highlight(M.buf, ns_id, hl_group, start_line + i, 0, -1)
  end
end

function M.scroll_to_bottom()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local line_count = vim.api.nvim_buf_line_count(M.buf)
    vim.api.nvim_win_set_cursor(M.win, { line_count, 0 })
  end
end

function M.send_input()
  local line = vim.api.nvim_get_current_line()
  if line == "" then
    return
  end

  local claude = require("cc_nvim.core.claude")
  claude.send_message(line)

  vim.api.nvim_set_current_line("")
end

function M.clear()
  if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
    vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, {})
  end
end

return M

