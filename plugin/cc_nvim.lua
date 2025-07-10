local cc_nvim = require("cc_nvim")

-- コマンド定義
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

-- コンテキスト送信コマンド
vim.api.nvim_create_user_command("CcSendBuffer", function()
  cc_nvim.send_buffer()
end, {
  desc = "Send current buffer to Claude Code"
})

vim.api.nvim_create_user_command("CcSendSelection", function()
  cc_nvim.send_selection()
end, {
  desc = "Send selection to Claude Code"
})

vim.api.nvim_create_user_command("CcSendLine", function()
  cc_nvim.send_line()
end, {
  desc = "Send current line to Claude Code"
})

-- キーマップ
vim.keymap.set("n", "<leader>cc", function()
  cc_nvim.toggle()
end, { desc = "Toggle Claude Code terminal" })

vim.keymap.set("n", "<leader>cb", function()
  cc_nvim.send_buffer()
end, { desc = "Send buffer to Claude Code" })

vim.keymap.set("v", "<leader>cs", function()
  cc_nvim.send_selection()
end, { desc = "Send selection to Claude Code" })

vim.keymap.set("n", "<leader>cl", function()
  cc_nvim.send_line()
end, { desc = "Send line to Claude Code" })
