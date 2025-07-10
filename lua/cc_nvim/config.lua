local M = {}

M.defaults = {
  claude_executable = "claude",
  panel = {
    position = "right", -- "right", "left", "bottom", "top"
    size = 40, -- percentage of screen
  },
  keymaps = {
    toggle = "<leader>cc",
    open = "<leader>co",
    send_file = "<leader>cf",
    send_selection = "<leader>cs",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get(key)
  return M.options[key]
end

return M