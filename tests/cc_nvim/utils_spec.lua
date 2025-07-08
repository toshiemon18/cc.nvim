local utils = require("cc_nvim.utils")

describe("cc_nvim.utils", function()
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

  describe("escape_pattern", function()
    it("should escape special pattern characters", function()
      local input = "test.file[1]"
      local result = utils.escape_pattern(input)
      assert.are.equal("test%.file%[1%]", result)
    end)

    it("should not escape alphanumeric characters", function()
      local input = "test123"
      local result = utils.escape_pattern(input)
      assert.are.equal("test123", result)
    end)

    it("should handle empty string", function()
      local result = utils.escape_pattern("")
      assert.are.equal("", result)
    end)
  end)

  describe("is_binary_file", function()
    it("should detect binary file", function()
      local temp_file = "/tmp/test_binary.bin"
      local file = io.open(temp_file, "wb")
      file:write(string.char(0, 1, 2, 3))
      file:close()
      
      local result = utils.is_binary_file(temp_file)
      assert.is_true(result)
      
      os.remove(temp_file)
    end)

    it("should detect text file", function()
      local temp_file = "/tmp/test_text.txt"
      local file = io.open(temp_file, "w")
      file:write("Hello World")
      file:close()
      
      local result = utils.is_binary_file(temp_file)
      assert.is_false(result)
      
      os.remove(temp_file)
    end)

    it("should return false for non-existent file", function()
      local result = utils.is_binary_file("/non/existent/file.bin")
      assert.is_false(result)
    end)
  end)

  describe("get_file_extension", function()
    it("should extract file extension", function()
      assert.are.equal("txt", utils.get_file_extension("file.txt"))
      assert.are.equal("lua", utils.get_file_extension("test.lua"))
      assert.are.equal("html", utils.get_file_extension("index.html"))
    end)

    it("should handle multiple dots", function()
      assert.are.equal("gz", utils.get_file_extension("file.tar.gz"))
      assert.are.equal("bak", utils.get_file_extension("config.ini.bak"))
    end)

    it("should return nil for no extension", function()
      assert.is_nil(utils.get_file_extension("README"))
      assert.is_nil(utils.get_file_extension("Makefile"))
    end)
  end)

  describe("get_relative_path", function()
    it("should return relative path", function()
      local base = "/home/user/project"
      local path = "/home/user/project/src/file.lua"
      local result = utils.get_relative_path(path, base)
      assert.are.equal("src/file.lua", result)
    end)

    it("should return full path if not under base", function()
      local base = "/home/user/project"
      local path = "/other/path/file.lua"
      local result = utils.get_relative_path(path, base)
      assert.are.equal(path, result)
    end)

    it("should handle same path", function()
      local path = "/home/user/project"
      local result = utils.get_relative_path(path, path)
      assert.are.equal("", result)
    end)
  end)

  describe("debounce", function()
    it("should debounce function calls", function()
      local call_count = 0
      local test_func = function()
        call_count = call_count + 1
      end
      
      local debounced = utils.debounce(test_func, 10)
      
      debounced()
      debounced()
      debounced()
      
      assert.are.equal(0, call_count)
      
      vim.wait(20, function() return call_count > 0 end)
      assert.are.equal(1, call_count)
    end)
  end)
end)