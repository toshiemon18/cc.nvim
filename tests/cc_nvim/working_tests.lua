-- Working unit tests for cc.nvim - All modules tested and passing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local function test_all_modules()
  print("🧪 Running cc.nvim unit tests...")
  
  local total_tests = 0
  local passed_tests = 0
  local failed_tests = 0
  
  local function test_assert(condition, message)
    total_tests = total_tests + 1
    if condition then
      passed_tests = passed_tests + 1
      print("  ✓ " .. message)
    else
      failed_tests = failed_tests + 1
      print("  ✗ " .. message)
    end
  end
  
  -- Test config module
  print("\n=== Testing config module ===")
  local config = require("cc_nvim.config")
  
  -- Test defaults
  test_assert(config.defaults.claude_executable == "claude", "Default claude_executable")
  test_assert(config.defaults.auto_start == false, "Default auto_start")
  test_assert(config.defaults.panel.position == "right", "Default panel position")
  test_assert(config.defaults.panel.size == 40, "Default panel size")
  test_assert(config.defaults.keymaps.toggle_panel == "<leader>cc", "Default keymap")
  
  -- Test setup
  config.setup()
  test_assert(config.options.claude_executable == "claude", "Setup with defaults")
  
  config.setup({ claude_executable = "custom-claude", panel = { position = "left" } })
  test_assert(config.options.claude_executable == "custom-claude", "Custom claude_executable")
  test_assert(config.options.panel.position == "left", "Custom panel position")
  test_assert(config.options.panel.auto_resize == true, "Preserved default value")
  
  -- Test get function
  test_assert(config.get("claude_executable") == "custom-claude", "get() function")
  test_assert(config.get("nonexistent") == nil, "get() returns nil for missing key")
  
  -- Test utils module
  print("\n=== Testing utils module ===")
  local utils = require("cc_nvim.utils")
  
  -- Test split_lines
  local lines = utils.split_lines("line1\nline2\nline3")
  test_assert(#lines == 3, "split_lines returns correct count")
  test_assert(lines[1] == "line1", "split_lines first line")
  test_assert(lines[2] == "line2", "split_lines second line")
  test_assert(lines[3] == "line3", "split_lines third line")
  
  lines = utils.split_lines("")
  test_assert(#lines == 1 and lines[1] == "", "split_lines handles empty string")
  
  lines = utils.split_lines("single")
  test_assert(#lines == 1 and lines[1] == "single", "split_lines handles single line")
  
  -- Test escape_pattern
  local escaped = utils.escape_pattern("test.file[1]")
  test_assert(escaped == "test%.file%[1%]", "escape_pattern works")
  
  escaped = utils.escape_pattern("test123")
  test_assert(escaped == "test123", "escape_pattern preserves alphanumeric")
  
  -- Test get_file_extension
  test_assert(utils.get_file_extension("test.lua") == "lua", "get_file_extension basic")
  test_assert(utils.get_file_extension("file.tar.gz") == "gz", "get_file_extension multiple dots")
  test_assert(utils.get_file_extension("README") == nil, "get_file_extension no extension")
  
  -- Test get_relative_path
  local rel_path = utils.get_relative_path("/home/user/project/src/file.lua", "/home/user/project")
  test_assert(rel_path == "src/file.lua", "get_relative_path works")
  
  rel_path = utils.get_relative_path("/other/path/file.lua", "/home/user/project")
  test_assert(rel_path == "/other/path/file.lua", "get_relative_path returns full path when not under base")
  
  -- Test parser module
  print("\n=== Testing parser module ===")
  local parser = require("cc_nvim.diff.parser")
  
  -- Test parse_claude_output
  local output = [[
File: test.lua
Line 1
```lua
print('hello world')
```
]]
  
  local result = parser.parse_claude_output(output)
  test_assert(#result == 1, "parse_claude_output returns 1 file")
  test_assert(result[1].file_path == "test.lua", "parse_claude_output file path")
  test_assert(#result[1].changes == 1, "parse_claude_output has 1 change")
  test_assert(result[1].changes[1].start_line == 1, "parse_claude_output start line")
  test_assert(result[1].changes[1].new_lines[1] == "print('hello world')", "parse_claude_output content")
  
  -- Test multiple files
  output = [[
File: test1.lua
Line 1
```lua
print('hello')
```

File: test2.lua
Line 5
```lua
print('world')
```
]]
  
  result = parser.parse_claude_output(output)
  test_assert(#result == 2, "parse_claude_output handles multiple files")
  test_assert(result[1].file_path == "test1.lua", "parse_claude_output first file")
  test_assert(result[2].file_path == "test2.lua", "parse_claude_output second file")
  
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
  test_assert(#result == 1, "parse_git_diff returns 1 file")
  test_assert(result[1].file_path == "test.lua", "parse_git_diff file path")
  test_assert(#result[1].changes == 1, "parse_git_diff has 1 change")
  
  -- Test validate_changes
  local changes = {
    {
      file_path = "test.lua",
      changes = {
        { start_line = 1, new_lines = {"print('hello')"} },
        { start_line = 0, new_lines = {"invalid"} }  -- Invalid
      }
    },
    {
      file_path = "",  -- Invalid
      changes = { { start_line = 1, new_lines = {"ignored"} } }
    }
  }
  
  result = parser.validate_changes(changes)
  test_assert(#result == 1, "validate_changes filters invalid files")
  test_assert(#result[1].changes == 1, "validate_changes filters invalid changes")
  
  -- Test format_change_summary
  local summary = parser.format_change_summary({ old_lines = {}, new_lines = {"a", "b"} })
  test_assert(summary == "Added 2 lines", "format_change_summary addition")
  
  summary = parser.format_change_summary({ old_lines = {"a", "b"}, new_lines = {} })
  test_assert(summary == "Removed 2 lines", "format_change_summary removal")
  
  summary = parser.format_change_summary({ old_lines = {"a"}, new_lines = {"b"} })
  test_assert(summary == "Modified 1 lines", "format_change_summary modification")
  
  -- Test calculate_change_stats
  changes = {
    {
      file_path = "file1.lua",
      changes = {
        { old_lines = {}, new_lines = {"new1", "new2"} },
        { old_lines = {"old1"}, new_lines = {} }
      }
    }
  }
  
  local stats = parser.calculate_change_stats(changes)
  test_assert(stats.total_files == 1, "calculate_change_stats total_files")
  test_assert(stats.total_changes == 2, "calculate_change_stats total_changes")
  test_assert(stats.lines_added == 2, "calculate_change_stats lines_added")
  test_assert(stats.lines_removed == 1, "calculate_change_stats lines_removed")
  
  -- Test diff module (with mocks)
  print("\n=== Testing diff module ===")
  
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
  
  -- Test create_session
  changes = {
    {
      file_path = "test.lua",
      changes = { { start_line = 1, new_lines = {"print('hello')"} } }
    }
  }
  
  local session = diff.create_session(changes)
  test_assert(session ~= nil, "create_session returns session")
  test_assert(#session.changes == 1, "create_session has changes")
  test_assert(session.state.current_index == 1, "create_session initial state")
  
  -- Test navigation
  local current_change = diff.get_current_change()
  test_assert(current_change ~= nil, "get_current_change returns change")
  test_assert(current_change.start_line == 1, "get_current_change correct line")
  
  local current_file = diff.get_current_file()
  test_assert(current_file ~= nil, "get_current_file returns file")
  test_assert(current_file.file_path == "test.lua", "get_current_file correct path")
  
  -- Test stats
  local stats = diff.get_stats()
  test_assert(stats.total == 1, "get_stats total")
  test_assert(stats.pending == 1, "get_stats pending")
  test_assert(stats.accepted == 0, "get_stats accepted initial")
  
  -- Test accept_change
  diff.accept_change()
  stats = diff.get_stats()
  test_assert(stats.accepted == 1, "accept_change updates stats")
  test_assert(stats.pending == 0, "accept_change removes from pending")
  
  -- Restore original require
  require = original_require
  
  -- Print summary
  print("\n=== Test Summary ===")
  print(string.format("Total: %d, Passed: %d, Failed: %d", total_tests, passed_tests, failed_tests))
  
  if failed_tests > 0 then
    print(string.format("❌ %d tests failed", failed_tests))
    return false
  else
    print("✅ All tests passed!")
    return true
  end
end

-- Run tests
local success = test_all_modules()
if not success then
  os.exit(1)
end