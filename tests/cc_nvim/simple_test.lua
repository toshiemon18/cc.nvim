-- Simple test to verify basic functionality
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Test config module
local config = require("cc_nvim.config")

print("Testing config module...")

-- Test setup
config.setup()
assert(config.options.claude_executable == "claude", "Default claude_executable should be 'claude'")
print("✓ Default config loaded")

-- Test with custom options
config.setup({ claude_executable = "custom-claude" })
assert(config.options.claude_executable == "custom-claude", "Custom claude_executable should be set")
print("✓ Custom config loaded")

-- Test get function
local executable = config.get("claude_executable")
assert(executable == "custom-claude", "get() should return custom value")
print("✓ Config get() function works")

-- Test utils module
local utils = require("cc_nvim.utils")

print("\nTesting utils module...")

-- Test split_lines
local lines = utils.split_lines("line1\nline2\nline3")
assert(#lines == 3, "split_lines should return 3 lines")
assert(lines[1] == "line1", "First line should be 'line1'")
print("✓ split_lines works")

-- Test escape_pattern
local escaped = utils.escape_pattern("test.file")
assert(escaped == "test%.file", "Dots should be escaped")
print("✓ escape_pattern works")

-- Test get_file_extension
local ext = utils.get_file_extension("test.lua")
assert(ext == "lua", "Extension should be 'lua'")
print("✓ get_file_extension works")

-- Test diff parser
local parser = require("cc_nvim.diff.parser")

print("\nTesting parser module...")

-- Test validate_changes
local changes = parser.validate_changes({
  {
    file_path = "test.lua",
    changes = {
      {
        start_line = 1,
        new_lines = {"print('hello')"}
      }
    }
  }
})

assert(#changes == 1, "Should have 1 validated change")
assert(changes[1].file_path == "test.lua", "File path should be preserved")
print("✓ validate_changes works")

-- Test format_change_summary
local summary = parser.format_change_summary({
  old_lines = {},
  new_lines = {"line1", "line2"}
})
assert(summary == "Added 2 lines", "Summary should indicate addition")
print("✓ format_change_summary works")

print("\n✅ All basic tests passed!")