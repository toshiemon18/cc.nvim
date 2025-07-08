local cc_nvim = require("cc_nvim")

vim.api.nvim_create_user_command("CcChat", function(opts)
  cc_nvim.chat(opts.args)
end, {
  nargs = "*",
  desc = "Start a chat session with Claude Code"
})

vim.api.nvim_create_user_command("CcSendFile", function(opts)
  cc_nvim.send_file(opts.args)
end, {
  nargs = "?",
  desc = "Send current file or specified file to Claude Code"
})

vim.api.nvim_create_user_command("CcApplyChanges", function()
  cc_nvim.apply_changes()
end, {
  desc = "Apply changes suggested by Claude Code"
})

vim.api.nvim_create_user_command("CcTogglePanel", function()
  cc_nvim.toggle_panel()
end, {
  desc = "Toggle the Claude Code panel"
})

vim.api.nvim_create_user_command("CcDiff", function()
  cc_nvim.review_changes()
end, {
  desc = "Review code changes in diff mode"
})

vim.api.nvim_create_user_command("CcGitDiff", function(opts)
  cc_nvim.git_diff(opts.args)
end, {
  nargs = "?",
  desc = "Show git diff in review mode"
})

vim.api.nvim_create_user_command("CcGitDiffStaged", function()
  local git = require("cc_nvim.git")
  local diff_output, error_msg = git.get_staged_diff()
  
  if not diff_output then
    vim.notify(error_msg or "No staged changes", vim.log.levels.WARN)
    return
  end
  
  local changes = git.create_git_diff_changes(diff_output, "Git Diff (Staged Changes)")
  local diff = require("cc_nvim.diff")
  diff.start_diff_mode(changes)
end, {
  desc = "Show staged git diff in review mode"
})

vim.keymap.set("n", "<leader>cc", function()
  cc_nvim.toggle_panel()
end, { desc = "Toggle Claude Code panel" })

vim.keymap.set("v", "<leader>cs", function()
  cc_nvim.send_selection()
end, { desc = "Send selection to Claude Code" })

vim.keymap.set("n", "<leader>cf", function()
  cc_nvim.send_file()
end, { desc = "Send current file to Claude Code" })

vim.keymap.set("n", "<leader>ca", function()
  cc_nvim.apply_changes()
end, { desc = "Apply Claude Code changes" })

vim.keymap.set("n", "<leader>cd", function()
  cc_nvim.review_changes()
end, { desc = "Review Claude Code changes" })

vim.keymap.set("n", "<leader>cg", function()
  cc_nvim.git_diff()
end, { desc = "Show git diff" })

vim.keymap.set("n", "<leader>cG", function()
  local git = require("cc_nvim.git")
  local diff_output, error_msg = git.get_staged_diff()
  
  if not diff_output then
    vim.notify(error_msg or "No staged changes", vim.log.levels.WARN)
    return
  end
  
  local changes = git.create_git_diff_changes(diff_output, "Git Diff (Staged Changes)")
  local diff = require("cc_nvim.diff")
  diff.start_diff_mode(changes)
end, { desc = "Show staged git diff" })