# cc.nvim

A Neovim plugin for integrating with Claude Code CLI, providing AI-powered coding assistance similar to Cursor and other AI coding tools.

## Features

- 🤖 **Interactive Chat Interface**: Chat with Claude Code directly from Neovim
- 📁 **File Sending**: Send current file or selection to Claude Code for analysis
- ✨ **Code Suggestions**: Get AI-powered code suggestions and apply them
- 🔍 **Diff Review Mode**: Review code changes with reviewit-style TUI interface
- 🔧 **Smart Integration**: Seamless integration with Claude Code CLI
- ⚡ **Lightweight**: Fast and efficient Lua implementation

## Installation

### Prerequisites

- Neovim 0.8+
- Claude Code CLI installed and configured
- Lua 5.1+

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "toshiemon18/cc.nvim",
  config = function()
    require("cc_nvim").setup({
      -- Configuration options
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "toshiemon18/cc.nvim",
  config = function()
    require("cc_nvim").setup()
  end
}
```

## Configuration

Default configuration:

```lua
require("cc_nvim").setup({
  claude_executable = "claude", -- Path to Claude Code CLI
  auto_start = false, -- Auto-start Claude Code session
  panel = {
    position = "right", -- Panel position
    size = 40, -- Panel size (percentage)
    auto_resize = true, -- Auto-resize panel
    border = "rounded", -- Border style
  },
  keymaps = {
    toggle_panel = "<leader>cc", -- Toggle panel
    send_file = "<leader>cf", -- Send current file
    send_selection = "<leader>cs", -- Send selection
    apply_changes = "<leader>ca", -- Apply changes
  },
  highlights = {
    user_message = "Comment",
    claude_message = "String",
    system_message = "WarningMsg",
    error_message = "ErrorMsg",
  },
  timeout = 30000, -- Timeout for Claude Code responses
  max_history = 100, -- Maximum chat history
})
```

## Usage

### Commands

- `:CcChat [message]` - Start chat or send message
- `:CcSendFile [path]` - Send file to Claude Code
- `:CcApplyChanges` - Apply suggested changes (opens diff review)
- `:CcDiff` - Review pending changes in diff mode
- `:CcGitDiff [commit/branch]` - Show git diff in review mode
- `:CcGitDiffStaged` - Show staged git diff in review mode
- `:CcTogglePanel` - Toggle the Claude Code panel

### Default Keymaps

- `<leader>cc` - Toggle Claude Code panel
- `<leader>cf` - Send current file to Claude Code
- `<leader>cs` - Send visual selection to Claude Code
- `<leader>ca` - Apply Claude Code changes (opens diff review)
- `<leader>cd` - Review pending changes in diff mode
- `<leader>cg` - Show git diff (unstaged changes)
- `<leader>cG` - Show staged git diff

### Panel Navigation

When the panel is open:
- `q` or `<Esc>` - Close panel
- `<CR>` - Send message (normal mode)
- `<C-CR>` - Send message (insert mode)

### Diff Review Mode

When reviewing changes:
- `j/k` - Next/Previous change
- `h/l` - Previous/Next file
- `Space` - Accept change
- `x` - Reject change
- `s` - Skip change
- `a` - Accept all changes
- `r` - Reject all changes
- `A` - Accept all changes in current file
- `R` - Reject all changes in current file
- `m` - Toggle display mode (side-by-side/inline/unified)
- `Enter` - Apply accepted changes
- `?` - Show help
- `q` - Quit diff mode

## Example Workflows

### Claude Code Integration
1. Open a file you want to work on
2. Press `<leader>cc` to open the Claude Code panel
3. Press `<leader>cf` to send the current file to Claude Code
4. Chat with Claude Code to get suggestions
5. Press `<leader>ca` to enter diff review mode
6. Review each change using `j/k` navigation
7. Accept/reject changes using `Space`/`x`
8. Press `Enter` to apply accepted changes

### Git Diff Review
1. Press `<leader>cg` to view unstaged changes
2. Or use `:CcGitDiff HEAD~1` to compare with previous commit
3. Navigate through changes with `j/k`
4. Use `m` to toggle between display modes
5. Press `q` to quit (git diffs are read-only)

### Common Git Diff Commands
- `:CcGitDiff` - Show unstaged changes
- `:CcGitDiff HEAD~1` - Compare with previous commit
- `:CcGitDiff main` - Compare with main branch
- `:CcGitDiff abc123..def456` - Compare commit range
- `:CcGitDiffStaged` - Show staged changes

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
