local M = {}

M.defaults = {
  claude_executable = "claude",
  auto_start = false,
  panel = {
    position = "right",
    size = 40,
    auto_resize = true,
    border = "rounded",
  },
  keymaps = {
    toggle_panel = "<leader>cc",
    send_file = "<leader>cf",
    send_selection = "<leader>cs",
    apply_changes = "<leader>ca",
    review_changes = "<leader>cd",
    git_diff = "<leader>cg",
    git_diff_staged = "<leader>cG",
  },
  highlights = {
    user_message = "Comment",
    claude_message = "String",
    system_message = "WarningMsg",
    error_message = "ErrorMsg",
  },
  diff = {
    mode = "side_by_side",
    context_lines = 3,
    show_line_numbers = true,
    wrap_lines = false,
    syntax_highlighting = true,
    split_ratio = 0.5,
    min_height = 10,
    border = "rounded",
  },
  timeout = 30000,
  max_history = 100,
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get(key)
  return M.options[key]
end

return M

