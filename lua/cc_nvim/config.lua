local M = {}

-- デフォルト設定
M.defaults = {
  claude_executable = "claude",
  terminal = {
    position = "bottom",      -- "bottom" | "top"
    size = 20,               -- 画面に対する％
    split_type = "horizontal" -- "horizontal" | "vertical"
  }
}

-- 現在の設定
M.options = {}

-- 設定の初期化
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

-- 設定値の取得
function M.get(key)
  return M.options[key]
end

return M