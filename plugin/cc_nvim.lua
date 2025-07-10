local cc_nvim = require("cc_nvim")

vim.api.nvim_create_user_command("CcOpen", function()
  cc_nvim.open()
end, {
  desc = "Open Claude Code terminal"
})

vim.api.nvim_create_user_command("CcClose", function()
  cc_nvim.close()
end, {
  desc = "Close Claude Code terminal"
})

vim.api.nvim_create_user_command("CcToggle", function()
  cc_nvim.toggle()
end, {
  desc = "Toggle Claude Code terminal"
})

vim.api.nvim_create_user_command("CcSendFile", function(opts)
  cc_nvim.send_file(opts.args)
end, {
  nargs = "?",
  desc = "Send current file or specified file to Claude Code"
})

vim.api.nvim_create_user_command("CcSendMessage", function(opts)
  cc_nvim.send_message(opts.args)
end, {
  nargs = "*",
  desc = "Send message to Claude Code"
})

vim.keymap.set("n", "<leader>cc", function()
  cc_nvim.toggle()
end, { desc = "Toggle Claude Code terminal" })

vim.keymap.set("v", "<leader>cs", function()
  cc_nvim.send_selection()
end, { desc = "Send selection to Claude Code" })

vim.keymap.set("n", "<leader>cf", function()
  cc_nvim.send_file()
end, { desc = "Send current file to Claude Code" })

vim.keymap.set("n", "<leader>co", function()
  cc_nvim.open()
end, { desc = "Open Claude Code terminal" })