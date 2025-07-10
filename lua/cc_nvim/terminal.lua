local M = {}
local config = require("cc_nvim.config")

-- ターミナル状態
M.terminal_buf = nil
M.terminal_win = nil
M.job_id = nil

-- ターミナルが開いているかチェック
function M.is_open()
  return M.terminal_buf 
    and vim.api.nvim_buf_is_valid(M.terminal_buf)
    and M.job_id 
    and vim.fn.jobwait({M.job_id}, 0)[1] == -1
end

-- ターミナルを開く
function M.open()
  -- 既に開いている場合は何もしない
  if M.is_open() then
    -- 既存のウィンドウにフォーカス
    local wins = vim.fn.win_findbuf(M.terminal_buf)
    if #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
    end
    return
  end

  -- 既存のターミナルをクリーンアップ
  M.close()

  -- 新しいターミナルを作成
  M.create_terminal()
end

-- ターミナルを閉じる
function M.close()
  -- 既にクローズ処理中の場合は何もしない
  if not M.terminal_buf then
    return
  end

  local buf_to_close = M.terminal_buf

  -- 状態を先にリセット（重複実行を防ぐため）
  M.terminal_buf = nil
  M.terminal_win = nil
  M.job_id = nil

  -- バッファが有効な場合のみ削除
  if vim.api.nvim_buf_is_valid(buf_to_close) then
    -- 安全にバッファを削除
    pcall(vim.api.nvim_buf_delete, buf_to_close, { force = true })
  end
end

-- トグル機能
function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

-- ターミナルを作成
function M.create_terminal()
  local terminal_config = config.get("terminal")
  local claude_cmd = config.get("claude_executable")

  -- belowright new で新規バッファを作成
  if terminal_config.position == "bottom" then
    vim.cmd("belowright new")
  else
    vim.cmd("aboveleft new")
  end

  -- ウィンドウサイズを設定
  M.set_window_size()

  -- ターミナルを開始（:terminal claude と同等）
  vim.cmd("terminal " .. claude_cmd)

  -- ターミナル情報を取得
  M.terminal_buf = vim.api.nvim_get_current_buf()
  M.terminal_win = vim.api.nvim_get_current_win()
  
  -- job_idを取得（ターミナルバッファから）
  M.job_id = vim.bo.channel

  -- バッファ名を設定
  vim.api.nvim_buf_set_name(M.terminal_buf, "Claude Code")

  -- 終了時のコールバックを設定
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = M.terminal_buf,
    callback = function()
      -- 状態のみリセット（バッファ削除は行わない）
      M.terminal_buf = nil
      M.terminal_win = nil
      M.job_id = nil
    end,
    once = true
  })

  -- ターミナルモードに入る
  vim.cmd("startinsert")
end

-- ウィンドウサイズを設定
function M.set_window_size()
  local terminal_config = config.get("terminal")
  
  if terminal_config.split_type == "horizontal" then
    local height = math.floor(vim.o.lines * terminal_config.size / 100)
    vim.api.nvim_win_set_height(0, height)
  else
    local width = math.floor(vim.o.columns * terminal_config.size / 100)
    vim.api.nvim_win_set_width(0, width)
  end
end

return M