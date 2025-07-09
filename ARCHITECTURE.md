# cc.nvim アーキテクチャ設計

## 1. システム概要

### 1.1 全体アーキテクチャ
```
┌─────────────────────────────────────────────────────────────┐
│                        Neovim                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                     cc.nvim                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │ │
│  │  │    UI       │  │    Core     │  │    Diff     │      │ │
│  │  │   Layer     │  │   Layer     │  │   Layer     │      │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │ │
│  │          │               │               │             │ │
│  │          └───────────────┼───────────────┘             │ │
│  │                          │                             │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │              Utils & Config                         │ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                                 │
                                 │ stdin/stdout
                                 │
                    ┌─────────────────────────┐
                    │     Claude Code CLI     │
                    └─────────────────────────┘
```

### 1.2 レイヤー構成
- **UI Layer**: ユーザーインターフェース（パネル、diff表示）
- **Core Layer**: Claude Code CLI との通信、セッション管理
- **Diff Layer**: コード変更の解析、適用、レビュー
- **Utils & Config**: 設定管理、ユーティリティ関数

## 2. 詳細設計

### 2.1 Core Layer (コア層)

#### 2.1.1 初期化システム (`init.lua`)
```lua
-- 責任範囲
- プラグイン全体の初期化
- 公開 API の提供
- 各モジュールの連携

-- 主要関数
- setup(opts): プラグイン設定
- chat(message): チャット開始
- send_file(path): ファイル送信
- send_selection(): 選択範囲送信
- apply_changes(): 変更適用
- review_changes(): 変更レビュー
- git_diff(): Git差分レビュー
- toggle_panel(): パネル切り替え
```

#### 2.1.2 設定管理 (`config.lua`)
```lua
-- 責任範囲
- デフォルト設定の定義
- ユーザー設定のマージ
- 設定値の提供

-- 設定構造
defaults = {
  claude_executable = "claude",
  panel = { position, size, border... },
  keymaps = { toggle_panel, send_file... },
  highlights = { user_message, claude_message... },
  diff = { mode, context_lines... },
  timeout = 30000,
  max_history = 100
}
```

#### 2.1.3 Claude通信 (`core/claude.lua`)
```lua
-- 責任範囲
- Claude Code CLI プロセス管理
- メッセージの送受信
- 出力の解析と変更検出

-- プロセス管理
start_session() -> handle, stdin, stdout, stderr
setup_output_handlers() -> 非同期出力処理
stop_session() -> クリーンアップ

-- 通信管理
send_message(message) -> stdin書き込み
process_output(data) -> 出力解析
extract_and_store_changes(data) -> 変更抽出
```

### 2.2 UI Layer (UI層)

#### 2.2.1 パネル管理 (`ui/panel.lua`)
```lua
-- 責任範囲
- チャットパネルの作成・管理
- メッセージの表示・フォーマット
- ユーザー入力の処理

-- ウィンドウ管理
create_buffer() -> バッファ作成
open() -> パネル表示
close() -> パネル非表示
toggle() -> 表示切り替え

-- メッセージ管理
append_message(sender, content) -> メッセージ追加
highlight_message() -> シンタックスハイライト
scroll_to_bottom() -> 自動スクロール
```

#### 2.2.2 Diff表示 (`ui/diff/renderer.lua`)
```lua
-- 責任範囲
- コード変更の視覚化
- サイドバイサイド表示
- シンタックスハイライト

-- 表示モード
render_side_by_side() -> 並列表示
render_unified() -> 統合表示
apply_syntax_highlighting() -> ハイライト適用
```

### 2.3 Diff Layer (差分層)

#### 2.3.1 差分管理 (`diff/init.lua`)
```lua
-- 責任範囲
- 差分セッションの管理
- 変更状態の追跡
- ユーザーアクションの処理

-- セッション管理
start_diff_mode(changes) -> 差分モード開始
start_git_diff_mode() -> Git差分モード
handle_user_action() -> ユーザー操作処理

-- 状態管理
- pending: 保留中
- accepted: 承認済み
- rejected: 拒否済み
```

#### 2.3.2 変更解析 (`diff/parser.lua`)
```lua
-- 責任範囲
- Claude出力の解析
- コードブロックの抽出
- ファイル変更の構造化

-- 解析処理
parse_claude_output(data) -> 変更リスト
extract_code_blocks() -> コードブロック抽出
parse_file_changes() -> ファイル変更解析
```

### 2.4 Git Layer (Git層)

#### 2.4.1 Git統合 (`git/init.lua`)
```lua
-- 責任範囲
- Git操作の実行
- 差分の取得・解析
- ステージング状態の管理

-- Git操作
get_diff(commit_or_branch) -> 差分取得
get_staged_changes() -> ステージング変更
format_git_diff() -> 差分フォーマット
```

### 2.5 Utils Layer (ユーティリティ層)

#### 2.5.1 共通機能 (`utils/init.lua`)
```lua
-- 責任範囲
- ファイル操作
- 文字列処理
- 共通ヘルパー関数

-- ファイル操作
read_file(path) -> ファイル内容読み取り
write_file(path, content) -> ファイル書き込み
file_exists(path) -> 存在確認

-- 文字列処理
split_lines(text) -> 行分割
trim_whitespace(text) -> 空白除去
```

## 3. データフロー

### 3.1 メッセージ送信フロー
```
User Input -> init.lua -> claude.lua -> Claude Code CLI
                                     -> panel.lua (表示)
```

### 3.2 レスポンス受信フロー
```
Claude Code CLI -> claude.lua -> diff/parser.lua -> 変更検出
                              -> panel.lua (表示)
                              -> diff/init.lua (差分準備)
```

### 3.3 変更適用フロー
```
User Action -> diff/init.lua -> claude.lua -> ファイル変更
                             -> ui/diff/renderer.lua (表示更新)
```

## 4. 状態管理

### 4.1 セッション状態
```lua
-- claude.lua
M.current_session = {
  handle = process_handle,
  stdin = stdin_pipe,
  stdout = stdout_pipe,
  stderr = stderr_pipe
}

M.message_history = {} -- メッセージ履歴
M.pending_changes = {} -- 保留中の変更
```

### 4.2 UI状態
```lua
-- panel.lua
M.buf = buffer_id       -- バッファID
M.win = window_id       -- ウィンドウID
M.is_open = boolean     -- 表示状態
```

### 4.3 差分状態
```lua
-- diff/init.lua
M.current_session = {
  changes = {},           -- 変更リスト
  current_index = 1,      -- 現在のインデックス
  accepted = {},          -- 承認済み変更
  rejected = {}           -- 拒否済み変更
}
```

## 5. イベント処理

### 5.1 非同期処理
```lua
-- libuv を使用した非同期処理
vim.loop.spawn() -> プロセス起動
pipe:read_start() -> 非同期読み取り
vim.schedule() -> メインスレッド実行
```

### 5.2 エラーハンドリング
```lua
-- エラー処理パターン
if not handle then
  vim.notify("エラーメッセージ", vim.log.levels.ERROR)
  return nil
end

-- 例外キャッチ
pcall(function()
  -- 危険な操作
end)
```

## 6. 拡張性設計

### 6.1 モジュール分離
- 各モジュールは独立して動作
- 明確な責任範囲の定義
- インターフェースの標準化

### 6.2 設定の柔軟性
- デフォルト設定の上書き可能
- 深いマージによる部分設定
- 実行時設定変更対応

### 6.3 プラグイン統合
- 標準的なNeovimプラグイン規約
- 他のプラグインとの衝突回避
- キーマップの競合解決

## 7. セキュリティ考慮

### 7.1 プロセス分離
- Claude Code CLI の独立実行
- 適切なプロセス終了処理
- リソースリークの防止

### 7.2 ファイルアクセス
- 読み取り専用での安全なアクセス
- パス検証によるセキュリティ
- 権限チェックの実装

## 8. パフォーマンス最適化

### 8.1 メモリ管理
- 履歴の上限設定 (max_history)
- 不要なデータの自動削除
- バッファの効率的な利用

### 8.2 レスポンス性
- 非同期処理による UI ブロック回避
- 適切なタイムアウト設定
- 段階的なデータ読み込み

## 9. テスト戦略

### 9.1 単体テスト
- 各モジュールの独立テスト
- モック使用による依存関係の分離
- エラーケースの網羅

### 9.2 統合テスト
- モジュール間の連携テスト
- 実際のフローの確認
- パフォーマンステスト

## 10. 保守性

### 10.1 コード品質
- 一貫した命名規則
- 適切なコメント
- 明確な関数責任

### 10.2 文書化
- API ドキュメント
- アーキテクチャ設計書
- 変更履歴の管理