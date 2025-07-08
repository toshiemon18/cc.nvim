-- Comprehensive test for all modules
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_config()
  local config = require("cc_nvim.config")
  
  print("=== Testing config module ===")
  
  -- Test defaults
  assert(config.defaults.claude_executable == "claude")
  assert(config.defaults.auto_start == false)
  assert(config.defaults.panel.position == "right")
  assert(config.defaults.panel.size == 40)
  assert(config.defaults.keymaps.toggle_panel == "<leader>cc")
  print("✓ Default values are correct")
  
  -- Test setup with no options
  config.setup()
  assert(config.options.claude_executable == "claude")
  print("✓ Setup with no options works")
  
  -- Test setup with custom options
  config.setup({
    claude_executable = "custom-claude",
    panel = { position = "left", size = 50 }
  })
  assert(config.options.claude_executable == "custom-claude")
  assert(config.options.panel.position == "left")
  assert(config.options.panel.size == 50)
  assert(config.options.panel.auto_resize == true) -- Should preserve default
  print("✓ Deep merge works correctly")
  
  -- Test get function
  assert(config.get("claude_executable") == "custom-claude")
  assert(config.get("panel").position == "left")
  assert(config.get("nonexistent") == nil)
  print("✓ get() function works")
  
  print("✅ Config module tests passed\n")
end

local function test_utils()
  local utils = require("cc_nvim.utils")
  
  print("=== Testing utils module ===")
  
  -- Test split_lines
  local lines = utils.split_lines("line1\nline2\nline3")
  assert(#lines == 3)
  assert(lines[1] == "line1")
  assert(lines[2] == "line2")
  assert(lines[3] == "line3")
  print("✓ split_lines works")
  
  -- Test split_lines with empty string
  lines = utils.split_lines("")
  assert(#lines == 1)
  assert(lines[1] == "")
  print("✓ split_lines handles empty string")
  
  -- Test escape_pattern
  local escaped = utils.escape_pattern("test.file[1]")
  assert(escaped == "test%.file%[1%]")
  print("✓ escape_pattern works")
  
  -- Test get_file_extension
  assert(utils.get_file_extension("test.lua") == "lua")
  assert(utils.get_file_extension("file.tar.gz") == "gz")
  assert(utils.get_file_extension("README") == nil)
  print("✓ get_file_extension works")
  
  -- Test get_relative_path
  local rel_path = utils.get_relative_path("/home/user/project/src/file.lua", "/home/user/project")
  assert(rel_path == "src/file.lua")
  print("✓ get_relative_path works")
  
  print("✅ Utils module tests passed\n")
end

local function test_parser()
  local parser = require("cc_nvim.diff.parser")
  
  print("=== Testing parser module ===")
  
  -- Test parse_claude_output
  local output = [[
File: test.lua
Line 1
```lua
print('hello world')
```
]]
  
  local result = parser.parse_claude_output(output)
  assert(#result == 1)
  assert(result[1].file_path == "test.lua")
  assert(#result[1].changes == 1)
  assert(result[1].changes[1].start_line == 1)
  assert(result[1].changes[1].new_lines[1] == "print('hello world')")
  print("✓ parse_claude_output works")
  
  -- Test parse_git_diff
  local diff = [[
diff --git a/test.lua b/test.lua
--- a/test.lua
+++ b/test.lua
@@ -1,3 +1,3 @@
 local M = {}
-print('old')
+print('new')
 return M
]]
  
  result = parser.parse_git_diff(diff)
  assert(#result == 1)
  assert(result[1].file_path == "test.lua")
  assert(#result[1].changes == 1)
  print("✓ parse_git_diff works")
  
  -- Test validate_changes
  local changes = {
    {
      file_path = "test.lua",
      changes = {
        {
          start_line = 1,
          new_lines = {"print('hello')"}
        },
        {
          start_line = 0, -- Invalid
          new_lines = {"invalid"}
        }
      }
    },
    {
      file_path = "", -- Invalid
      changes = {
        {
          start_line = 1,
          new_lines = {"should be ignored"}
        }
      }
    }
  }
  
  result = parser.validate_changes(changes)
  assert(#result == 1)
  assert(result[1].file_path == "test.lua")
  assert(#result[1].changes == 1)
  print("✓ validate_changes works")
  
  -- Test format_change_summary
  local summary = parser.format_change_summary({
    old_lines = {},
    new_lines = {"line1", "line2"}
  })
  assert(summary == "Added 2 lines")
  
  summary = parser.format_change_summary({
    old_lines = {"line1", "line2"},
    new_lines = {}
  })
  assert(summary == "Removed 2 lines")
  
  summary = parser.format_change_summary({
    old_lines = {"old"},
    new_lines = {"new"}
  })
  assert(summary == "Modified 1 lines")
  print("✓ format_change_summary works")
  
  -- Test calculate_change_stats
  changes = {
    {
      file_path = "file1.lua",
      changes = {
        {
          old_lines = {},
          new_lines = {"new1", "new2"}
        },
        {
          old_lines = {"old1"},
          new_lines = {}
        }
      }
    }
  }
  
  local stats = parser.calculate_change_stats(changes)
  assert(stats.total_files == 1)
  assert(stats.total_changes == 2)
  assert(stats.lines_added == 2)
  assert(stats.lines_removed == 1)
  print("✓ calculate_change_stats works")
  
  print("✅ Parser module tests passed\n")
end

local function test_diff_module()
  -- Mock dependencies
  local original_require = require
  require = function(name)
    if name == "cc_nvim.ui.diff" then
      return {
        open = function() end,
        close = function() end,
        refresh = function() end,
        toggle_display_mode = function() end
      }
    elseif name == "cc_nvim.git" then
      return {
        is_git_repository = function() return true end,
        get_git_diff = function() return "mock diff" end,
        create_git_diff_changes = function() return {} end,
        get_commit_info = function() return nil end
      }
    end
    return original_require(name)
  end
  
  local diff = require("cc_nvim.diff")
  
  print("=== Testing diff module ===")
  
  -- Test create_session
  local changes = {
    {
      file_path = "test.lua",
      changes = {
        {
          start_line = 1,
          new_lines = {"print('hello')"}
        }
      }
    }
  }
  
  local session = diff.create_session(changes)
  assert(session ~= nil)
  assert(#session.changes == 1)
  assert(session.state.current_index == 1)
  print("✓ create_session works")
  
  -- Test get_current_change
  local current_change = diff.get_current_change()
  assert(current_change ~= nil)
  assert(current_change.start_line == 1)
  print("✓ get_current_change works")
  
  -- Test get_current_file
  local current_file = diff.get_current_file()
  assert(current_file ~= nil)
  assert(current_file.file_path == "test.lua")
  print("✓ get_current_file works")
  
  -- Test get_stats
  local stats = diff.get_stats()
  assert(stats.total == 1)
  assert(stats.pending == 1)
  assert(stats.accepted == 0)
  assert(stats.rejected == 0)
  print("✓ get_stats works")
  
  -- Test accept_change
  diff.accept_change()
  stats = diff.get_stats()
  assert(stats.accepted == 1)
  assert(stats.pending == 0)
  print("✓ accept_change works")
  
  -- Restore original require
  require = original_require
  
  print("✅ Diff module tests passed\n")
end

-- Run all tests
test_config()
test_utils()
test_parser()
test_diff_module()

print("🎉 All comprehensive tests passed!")