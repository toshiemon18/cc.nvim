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

-- キーマップ
vim.keymap.set("n", "<leader>cc", function()
  cc_nvim.toggle()
end, { desc = "Toggle Claude Code terminal" })