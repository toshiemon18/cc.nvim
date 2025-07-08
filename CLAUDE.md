# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

cc.nvim is a Neovim plugin that provides integration with Claude Code CLI. It enables AI-powered coding assistance directly within Neovim, similar to Cursor and other AI coding tools.

## Testing

Run tests using:
```bash
# Run all tests (using busted - Lua testing framework)
busted tests/
```

The project uses busted for testing with test files located in `tests/` directory following the `*_spec.lua` naming convention.

## Architecture

### Core Components

- **Main Module (`lua/cc_nvim/init.lua`)**: Entry point and primary API that orchestrates all functionality
- **Configuration (`lua/cc_nvim/config.lua`)**: Handles plugin configuration with deep merge support for user options
- **Claude Core (`lua/cc_nvim/core/claude.lua`)**: Manages Claude Code CLI process communication via libuv, handles message history and change extraction
- **UI Panel (`lua/cc_nvim/ui/panel.lua`)**: Interactive chat interface for Claude Code communication
- **Diff System (`lua/cc_nvim/diff/`)**: Handles code change review with parser and renderer components
- **Git Integration (`lua/cc_nvim/git/`)**: Provides git diff review functionality
- **Utilities (`lua/cc_nvim/utils/`)**: Common utility functions

### Key Integration Points

The plugin integrates with Claude Code CLI through:
- Process spawning using `vim.loop.spawn()`
- Stdin/stdout communication for chat messages
- Change detection and parsing from Claude responses
- File content sending and selection sharing

### Plugin Structure

```
lua/cc_nvim/
├── init.lua          # Main API and setup
├── config.lua        # Configuration management
├── core/
│   └── claude.lua    # Claude Code CLI integration
├── ui/
│   ├── panel.lua     # Chat interface
│   └── diff/         # Diff UI components
├── diff/
│   ├── init.lua      # Diff mode orchestration
│   └── parser.lua    # Change parsing logic
├── git/
│   └── init.lua      # Git diff functionality
└── utils/
    └── init.lua      # Utility functions
```

## Default Configuration

The plugin provides extensive configuration through `config.defaults` in `lua/cc_nvim/config.lua`:

- Claude executable path: `"claude"`
- Panel position: right side, 40% width
- Keymaps: `<leader>cc` (toggle), `<leader>cf` (send file), `<leader>cs` (send selection), `<leader>ca` (apply changes)
- Diff mode: side-by-side with syntax highlighting
- Timeout: 30 seconds for Claude responses

## Development Notes

- Uses Lua 5.1+ and Neovim 0.8+ APIs
- Leverages `vim.loop` (libuv) for process management
- Implements deep table merging for configuration
- Follows Neovim plugin conventions for structure and naming
- Change detection parses Claude responses for code blocks and file references
- Diff system supports multiple display modes (side-by-side, inline, unified)