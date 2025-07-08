local claude = require("cc_nvim.core.claude")

describe("cc_nvim.core.claude", function()
  before_each(function()
    claude.current_session = nil
    claude.message_history = {}
    claude.pending_changes = {}
  end)

  describe("start_session", function()
    it("should return existing session if already started", function()
      local mock_session = { handle = {}, pid = 123 }
      claude.current_session = mock_session
      
      local result = claude.start_session()
      assert.are.same(mock_session, result)
    end)

  end)


  describe("contains_code_changes", function()
    it("should detect code blocks", function()
      local data = "Here is some code:\n```lua\nprint('hello')\n```"
      assert.is_true(claude.contains_code_changes(data))
    end)

    it("should detect file references", function()
      local data = "File: test.lua\nSome content"
      assert.is_true(claude.contains_code_changes(data))
    end)

    it("should detect line numbers", function()
      local data = "Line 42: some code here"
      assert.is_true(claude.contains_code_changes(data))
    end)

    it("should detect line ranges", function()
      local data = "Lines 10-15: some code here"
      assert.is_true(claude.contains_code_changes(data))
    end)

    it("should return false for plain text", function()
      local data = "This is just plain text without code"
      assert.is_false(claude.contains_code_changes(data))
    end)
  end)




  describe("get_pending_changes", function()
    it("should return current pending changes", function()
      local mock_changes = { { file_path = "test.lua" } }
      claude.pending_changes = mock_changes
      
      local result = claude.get_pending_changes()
      assert.are.same(mock_changes, result)
    end)
  end)

  describe("clear_pending_changes", function()
    it("should clear pending changes", function()
      claude.pending_changes = { { file_path = "test.lua" } }
      
      claude.clear_pending_changes()
      
      assert.are.same({}, claude.pending_changes)
    end)
  end)

  describe("stop_session", function()
    it("should close session handle", function()
      local handle_closed = false
      local mock_session = {
        handle = {
          close = function()
            handle_closed = true
          end
        }
      }
      
      claude.current_session = mock_session
      
      claude.stop_session()
      
      assert.is_true(handle_closed)
      assert.is_nil(claude.current_session)
    end)

    it("should handle nil session gracefully", function()
      claude.current_session = nil
      
      assert.has_no.errors(function()
        claude.stop_session()
      end)
    end)
  end)
end)