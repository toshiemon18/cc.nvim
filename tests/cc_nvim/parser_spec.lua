local parser = require("cc_nvim.diff.parser")

describe("cc_nvim.diff.parser", function()
  describe("parse_claude_output", function()
    it("should handle empty output", function()
      local result = parser.parse_claude_output("")
      assert.are.equal(0, #result)
    end)

    it("should handle output without code blocks", function()
      local output = "This is just plain text without any code changes"
      local result = parser.parse_claude_output(output)
      assert.are.equal(0, #result)
    end)
  end)

  describe("parse_git_diff", function()
    it("should handle empty diff", function()
      local result = parser.parse_git_diff("")
      assert.are.equal(0, #result)
    end)
  end)

  describe("create_manual_change", function()
    it("should create manual change structure", function()
      local old_lines = {"old line 1", "old line 2"}
      local new_lines = {"new line 1", "new line 2"}
      
      local result = parser.create_manual_change("test.lua", 5, 6, old_lines, new_lines)
      
      assert.are.equal("test.lua", result.file_path)
      assert.are.equal(1, #result.changes)
      
      local change = result.changes[1]
      assert.are.equal(5, change.start_line)
      assert.are.equal(6, change.end_line)
      assert.are.same(old_lines, change.old_lines)
      assert.are.same(new_lines, change.new_lines)
      assert.are.equal("pending", change.status)
    end)
  end)

  describe("validate_changes", function()
    it("should validate and clean up changes", function()
      local changes = {
        {
          file_path = "test.lua",
          changes = {
            {
              start_line = 1,
              end_line = 2,
              new_lines = {"line1", "line2"}
            },
            {
              start_line = 0,  -- Invalid line number
              new_lines = {"invalid"}
            }
          }
        },
        {
          file_path = "",  -- Invalid file path
          changes = {
            {
              start_line = 1,
              new_lines = {"should be ignored"}
            }
          }
        }
      }
      
      local result = parser.validate_changes(changes)
      
      assert.are.equal(1, #result)
      assert.are.equal("test.lua", result[1].file_path)
      assert.are.equal(1, #result[1].changes)
      assert.are.equal(1, result[1].changes[1].start_line)
    end)

    it("should set default values for missing fields", function()
      local changes = {
        {
          file_path = "test.lua",
          changes = {
            {
              start_line = 1
            }
          }
        }
      }
      
      local result = parser.validate_changes(changes)
      
      local change = result[1].changes[1]
      assert.are.equal(1, change.end_line)
      assert.are.same({}, change.old_lines)
      assert.are.same({}, change.new_lines)
      assert.are.equal("", change.description)
      assert.are.equal("pending", change.status)
    end)
  end)

  describe("get_file_content", function()
    it("should read file content", function()
      local temp_file = "/tmp/test_parser.lua"
      local content = {"line1", "line2", "line3"}
      
      vim.fn.writefile(content, temp_file)
      
      local result = parser.get_file_content(temp_file)
      
      assert.are.same(content, result)
      os.remove(temp_file)
    end)

    it("should return empty table for non-existent file", function()
      local result = parser.get_file_content("/non/existent/file.lua")
      assert.are.same({}, result)
    end)
  end)

  describe("get_context_lines", function()
    it("should return context lines around change", function()
      local temp_file = "/tmp/test_context.lua"
      local content = {"line1", "line2", "line3", "line4", "line5", "line6", "line7"}
      
      vim.fn.writefile(content, temp_file)
      
      local result = parser.get_context_lines(temp_file, 3, 5, 2)
      
      assert.are.equal(7, #result)
      assert.are.equal(1, result[1].line_number)
      assert.are.equal("line1", result[1].content)
      assert.is_false(result[1].is_changed)
      
      assert.are.equal(3, result[3].line_number)
      assert.are.equal("line3", result[3].content)
      assert.is_true(result[3].is_changed)
      
      os.remove(temp_file)
    end)
  end)

  describe("format_change_summary", function()
    it("should format addition", function()
      local change = {
        old_lines = {},
        new_lines = {"line1", "line2"}
      }
      
      local result = parser.format_change_summary(change)
      assert.are.equal("Added 2 lines", result)
    end)

    it("should format removal", function()
      local change = {
        old_lines = {"line1", "line2"},
        new_lines = {}
      }
      
      local result = parser.format_change_summary(change)
      assert.are.equal("Removed 2 lines", result)
    end)

    it("should format modification", function()
      local change = {
        old_lines = {"old line"},
        new_lines = {"new line"}
      }
      
      local result = parser.format_change_summary(change)
      assert.are.equal("Modified 1 lines", result)
    end)

    it("should format size change", function()
      local change = {
        old_lines = {"old line"},
        new_lines = {"new line 1", "new line 2"}
      }
      
      local result = parser.format_change_summary(change)
      assert.are.equal("Changed 1 lines to 2 lines", result)
    end)
  end)

  describe("calculate_change_stats", function()
    it("should calculate statistics", function()
      local changes = {
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
        },
        {
          file_path = "file2.lua",
          changes = {
            {
              old_lines = {"old1"},
              new_lines = {"new1"}
            }
          }
        }
      }
      
      local result = parser.calculate_change_stats(changes)
      
      assert.are.equal(2, result.total_files)
      assert.are.equal(3, result.total_changes)
      assert.are.equal(2, result.lines_added)
      assert.are.equal(1, result.lines_removed)
      assert.are.equal(1, result.lines_modified)
    end)
  end)
end)