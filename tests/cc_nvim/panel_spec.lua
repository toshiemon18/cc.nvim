local config = require("cc_nvim.config")

describe("cc_nvim.ui.panel", function()
  local panel

  before_each(function()
    -- Reset config before each test
    config.options = {}
    
    -- Mock vim APIs
    _G.vim = {
      api = {
        nvim_create_buf = function() return 1 end,
        nvim_buf_is_valid = function() return true end,
        nvim_buf_set_option = function() end,
        nvim_buf_set_name = function() end,
        nvim_set_hl = function() end,
        nvim_create_namespace = function() return 1 end,
        nvim_buf_add_highlight = function() end,
        nvim_open_win = function() return 1 end,
        nvim_win_is_valid = function() return true end,
        nvim_win_set_option = function() end,
        nvim_win_close = function() end,
        nvim_buf_line_count = function() return 1 end,
        nvim_buf_set_lines = function() end,
        nvim_get_current_line = function() return "test message" end,
        nvim_set_current_line = function() end,
        nvim_win_set_cursor = function() end,
        nvim_create_autocmd = function() end,
      },
      keymap = {
        set = function() end,
      },
      o = {
        columns = 80,
        lines = 24,
      },
      split = function(str, sep)
        local result = {}
        for match in (str .. sep):gmatch("(.-)" .. sep) do
          table.insert(result, match)
        end
        return result
      end,
      tbl_deep_extend = function(behavior, ...)
        local result = {}
        for _, tbl in ipairs({...}) do
          for k, v in pairs(tbl) do
            if type(v) == "table" and type(result[k]) == "table" then
              result[k] = vim.tbl_deep_extend(behavior, result[k], v)
            else
              result[k] = v
            end
          end
        end
        return result
      end,
    }
    
    -- Mock os.date
    _G.os = {
      date = function() return "12:34:56" end,
    }
    
    -- Fresh require of panel module
    package.loaded["cc_nvim.ui.panel"] = nil
    panel = require("cc_nvim.ui.panel")
  end)

  describe("setup_highlights", function()
    it("should handle nil highlights config gracefully", function()
      -- Given: config returns nil for highlights
      config.setup() -- This sets up defaults, but we'll mock get to return nil
      local original_get = config.get
      config.get = function(key)
        if key == "highlights" then
          return nil
        end
        return original_get(key)
      end
      
      -- When: setup_highlights is called
      local success, error = pcall(panel.setup_highlights)
      
      -- Then: it should not error and return gracefully
      assert.is_true(success)
      assert.is_nil(error)
      
      -- Restore original get function
      config.get = original_get
    end)
    
    it("should set highlights when config is available", function()
      -- Given: config has highlights
      config.setup({
        highlights = {
          user_message = "Comment",
          claude_message = "String",
        }
      })
      
      local highlight_calls = {}
      vim.api.nvim_set_hl = function(ns, name, opts)
        table.insert(highlight_calls, { ns = ns, name = name, opts = opts })
      end
      
      -- When: setup_highlights is called
      panel.setup_highlights()
      
      -- Then: highlights should be set
      assert.are.equal(2, #highlight_calls)
      assert.are.equal("CcNvimUserMessage", highlight_calls[1].name)
      assert.are.equal("CcNvimClaudeMessage", highlight_calls[2].name)
    end)
    
    it("should handle empty highlights config", function()
      -- Given: config has empty highlights
      config.setup({ highlights = {} })
      
      local highlight_calls = {}
      vim.api.nvim_set_hl = function(ns, name, opts)
        table.insert(highlight_calls, { ns = ns, name = name, opts = opts })
      end
      
      -- When: setup_highlights is called
      panel.setup_highlights()
      
      -- Then: no highlights should be set
      assert.are.equal(0, #highlight_calls)
    end)
  end)

  describe("create_buffer", function()
    it("should create buffer and setup highlights without error", function()
      -- Given: config is properly set up
      config.setup()
      
      -- When: create_buffer is called
      local success, result = pcall(panel.create_buffer)
      
      -- Then: it should succeed
      assert.is_true(success)
      assert.is_number(result)
    end)
    
    it("should handle missing config gracefully", function()
      -- Given: config is not set up (options is empty)
      config.options = {}
      
      -- When: create_buffer is called
      local success, result = pcall(panel.create_buffer)
      
      -- Then: it should not error
      assert.is_true(success)
    end)
  end)

  describe("open", function()
    it("should open panel without error even with missing config", function()
      -- Given: minimal config
      config.setup({
        panel = {
          size = 40,
          border = "rounded"
        }
      })
      
      -- When: open is called
      local success, error = pcall(panel.open)
      
      -- Then: it should succeed
      assert.is_true(success)
      assert.is_nil(error)
    end)
  end)
end)