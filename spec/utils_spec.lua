require "spec.spec_helper"

describe("cc_nvim.utils", function()
  local utils

  before_each(function()
    package.loaded["cc_nvim.utils"] = nil
    utils = require("cc_nvim.utils")
  end)

  describe("read_file", function()
    it("should read file content", function()
      local temp_file = "/tmp/test_file.txt"
      local content = "Hello, World!"
      
      local file = io.open(temp_file, "w")
      file:write(content)
      file:close()
      
      local result = utils.read_file(temp_file)
      assert.are.equal(content, result)
      
      os.remove(temp_file)
    end)

    it("should return nil for non-existent file", function()
      local result = utils.read_file("/non/existent/file.txt")
      assert.is_nil(result)
    end)
  end)

  describe("write_file", function()
    it("should write content to file", function()
      local temp_file = "/tmp/test_write.txt"
      local content = "Test content"
      
      local success = utils.write_file(temp_file, content)
      assert.is_true(success)
      
      local file = io.open(temp_file, "r")
      local result = file:read("*all")
      file:close()
      
      assert.are.equal(content, result)
      os.remove(temp_file)
    end)

    it("should return false for invalid path", function()
      local result = utils.write_file("/invalid/path/file.txt", "content")
      assert.is_false(result)
    end)
  end)

  describe("split_lines", function()
    it("should split string into lines", function()
      local text = "line1\nline2\nline3"
      local result = utils.split_lines(text)
      
      assert.are.equal(3, #result)
      assert.are.equal("line1", result[1])
      assert.are.equal("line2", result[2])
      assert.are.equal("line3", result[3])
    end)

    it("should handle empty string", function()
      local result = utils.split_lines("")
      assert.are.equal(1, #result)
      assert.are.equal("", result[1])
    end)

    it("should handle single line", function()
      local result = utils.split_lines("single line")
      assert.are.equal(1, #result)
      assert.are.equal("single line", result[1])
    end)
  end)
end)