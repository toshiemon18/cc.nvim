require "spec.spec_helper"

describe("cc_nvim.config", function()
  local config

  before_each(function()
    -- Clear package cache to ensure fresh require
    package.loaded["cc_nvim.config"] = nil
    config = require("cc_nvim.config")
    config.options = {}
  end)

  describe("setup", function()
    it("should use default options when no opts provided", function()
      config.setup()
      assert.are.same(config.defaults, config.options)
    end)

    it("should merge provided options with defaults", function()
      local opts = {
        claude_executable = "custom-claude",
        panel = {
          position = "left",
          size = 50
        }
      }
      
      config.setup(opts)
      
      assert.are.equal("custom-claude", config.options.claude_executable)
      assert.are.equal("left", config.options.panel.position)
      assert.are.equal(50, config.options.panel.size)
      assert.are.equal(true, config.options.panel.auto_resize)
    end)

    it("should deeply merge nested options", function()
      local opts = {
        keymaps = {
          toggle_panel = "<leader>t"
        }
      }
      
      config.setup(opts)
      
      assert.are.equal("<leader>t", config.options.keymaps.toggle_panel)
      assert.are.equal("<leader>cf", config.options.keymaps.send_file)
    end)
  end)

  describe("get", function()
    it("should return option value by key", function()
      config.setup({ claude_executable = "test-claude" })
      
      assert.are.equal("test-claude", config.get("claude_executable"))
    end)

    it("should return nil for non-existent key", function()
      config.setup()
      
      assert.is_nil(config.get("non_existent"))
    end)

    it("should return nested option value", function()
      config.setup()
      
      local panel = config.get("panel")
      assert.are.equal("right", panel.position)
      assert.are.equal(40, panel.size)
    end)
  end)

  describe("defaults", function()
    it("should have correct default values", function()
      assert.are.equal("claude", config.defaults.claude_executable)
      assert.are.equal(false, config.defaults.auto_start)
      assert.are.equal("right", config.defaults.panel.position)
      assert.are.equal(40, config.defaults.panel.size)
      assert.are.equal(true, config.defaults.panel.auto_resize)
      assert.are.equal("rounded", config.defaults.panel.border)
    end)

    it("should have correct keymap defaults", function()
      local keymaps = config.defaults.keymaps
      assert.are.equal("<leader>cc", keymaps.toggle_panel)
      assert.are.equal("<leader>cf", keymaps.send_file)
      assert.are.equal("<leader>cs", keymaps.send_selection)
    end)

    it("should have correct performance defaults", function()
      assert.are.equal(30000, config.defaults.timeout)
      assert.are.equal(100, config.defaults.max_history)
    end)
  end)
end)