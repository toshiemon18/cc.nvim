local M = {}

local config = require("cc_nvim.config")
local terminal = require("cc_nvim.terminal")

-- プラグインのセットアップ
function M.setup(opts)
  config.setup(opts)
end

-- ターミナルを開く
function M.open()
  terminal.open()
end

-- ターミナルを閉じる
function M.close()
  terminal.close()
end

-- ターミナルをトグル
function M.toggle()
  terminal.toggle()
end

-- ターミナルが開いているかチェック
function M.is_open()
  return terminal.is_open()
end

return M