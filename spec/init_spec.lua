require "spec.spec_helper"

describe("cc_nvim", function()
  local cc_nvim

  before_each(function()
    package.loaded["cc_nvim"] = nil
    package.loaded["cc_nvim.config"] = nil
    package.loaded["cc_nvim.core.claude"] = nil
    package.loaded["cc_nvim.utils"] = nil
    cc_nvim = require("cc_nvim")
  end)

  describe("module structure", function()
    it("should have required functions", function()
      assert.is_function(cc_nvim.setup)
      assert.is_function(cc_nvim.open)
      assert.is_function(cc_nvim.close)
      assert.is_function(cc_nvim.toggle)
      assert.is_function(cc_nvim.send_file)
      assert.is_function(cc_nvim.send_selection)
      assert.is_function(cc_nvim.send_message)
      assert.is_function(cc_nvim.is_open)
    end)

    it("should expose submodules", function()
      assert.is_table(cc_nvim.config)
      assert.is_table(cc_nvim.claude)
      assert.is_table(cc_nvim.utils)
    end)
  end)

  describe("setup", function()
    it("should call config.setup", function()
      local opts = { test = "option" }
      -- Should not error
      cc_nvim.setup(opts)
    end)

    it("should work without options", function()
      -- Should not error
      cc_nvim.setup()
    end)
  end)

  describe("open", function()
    it("should open Claude Code terminal", function()
      -- Should not error
      cc_nvim.open()
    end)
  end)

  describe("close", function()
    it("should close Claude Code terminal", function()
      -- Should not error
      cc_nvim.close()
    end)
  end)

  describe("toggle", function()
    it("should toggle Claude Code terminal", function()
      -- Should not error
      cc_nvim.toggle()
    end)
  end)

  describe("send_file", function()
    it("should handle file path", function()
      -- Should not error (will fail to read file but shouldn't crash)
      cc_nvim.send_file("/test/path.lua")
    end)

    it("should use current file if no path provided", function()
      -- Should not error
      cc_nvim.send_file()
    end)
  end)

  describe("send_selection", function()
    it("should handle selection", function()
      -- Should not error
      cc_nvim.send_selection()
    end)
  end)

  describe("send_message", function()
    it("should send message", function()
      -- Should not error
      cc_nvim.send_message("test")
    end)
  end)

  describe("is_open", function()
    it("should return terminal status", function()
      local result = cc_nvim.is_open()
      assert.is_boolean(result)
    end)
  end)
end)