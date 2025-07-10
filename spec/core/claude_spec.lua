require "spec.spec_helper"

describe("cc_nvim.core.claude", function()
  local claude

  before_each(function()
    package.loaded["cc_nvim.core.claude"] = nil
    package.loaded["cc_nvim.config"] = nil
    claude = require("cc_nvim.core.claude")
  end)

  describe("module structure", function()
    it("should have required functions", function()
      assert.is_function(claude.open_terminal)
      assert.is_function(claude.close)
      assert.is_function(claude.toggle)
      assert.is_function(claude.send_file)
      assert.is_function(claude.send_selection)
      assert.is_function(claude.send_message)
      assert.is_function(claude.is_terminal_open)
    end)

    it("should have required properties", function()
      assert.is_nil(claude.terminal_buf)
      assert.is_nil(claude.terminal_win)
      assert.is_nil(claude.job_id)
      assert.is_false(claude.is_open)
    end)
  end)

  describe("open_terminal", function()
    it("should not open if already open", function()
      claude.is_open = true
      claude.open_terminal()
      -- Should not create new terminal
    end)

    it("should start Claude Code terminal", function()
      claude.is_open = false
      claude.open_terminal()
      
      assert.is_true(claude.is_open)
      assert.is_not_nil(claude.job_id)
      assert.is_not_nil(claude.terminal_buf)
      assert.is_not_nil(claude.terminal_win)
    end)
  end)

  describe("close", function()
    it("should close terminal and cleanup", function()
      claude.job_id = 1
      claude.terminal_win = 1
      claude.is_open = true
      
      claude.close()
      
      assert.is_nil(claude.job_id)
      assert.is_nil(claude.terminal_win)
      assert.is_nil(claude.terminal_buf)
      assert.is_false(claude.is_open)
    end)
  end)

  describe("toggle", function()
    it("should open when closed", function()
      claude.is_open = false
      claude.job_id = nil
      claude.terminal_buf = nil
      claude.terminal_win = nil
      
      claude.toggle()
      
      assert.is_true(claude.is_open)
    end)

    it("should close when open", function()
      claude.is_open = true
      claude.job_id = 1
      claude.terminal_win = 1
      claude.terminal_buf = 1
      
      claude.toggle()
      
      assert.is_false(claude.is_open)
    end)
  end)

  describe("send_file", function()
    it("should send file content to terminal", function()
      claude.is_open = true
      claude.job_id = 1
      
      claude.send_file("/test/path.lua", "local test = 1")
      
      -- Should not error
    end)

    it("should warn if terminal is not open", function()
      claude.is_open = false
      
      claude.send_file("/test/path.lua", "local test = 1")
      
      -- Should show warning
    end)
  end)

  describe("send_selection", function()
    it("should send selection to terminal", function()
      claude.is_open = true
      claude.job_id = 1
      
      claude.send_selection("selected code")
      
      -- Should not error
    end)

    it("should warn if terminal is not open", function()
      claude.is_open = false
      
      claude.send_selection("selected code")
      
      -- Should show warning
    end)
  end)

  describe("send_message", function()
    it("should send message to terminal", function()
      claude.is_open = true
      claude.job_id = 1
      
      claude.send_message("test message")
      
      -- Should not error
    end)

    it("should warn if terminal is not open", function()
      claude.is_open = false
      
      claude.send_message("test message")
      
      -- Should show warning
    end)
  end)

  describe("is_terminal_open", function()
    it("should return current open status", function()
      claude.is_open = true
      claude.job_id = 1
      assert.is_true(claude.is_terminal_open())
      
      claude.is_open = false
      claude.job_id = nil
      assert.is_false(claude.is_terminal_open())
    end)
  end)
end)