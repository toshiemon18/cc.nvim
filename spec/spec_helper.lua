-- Test helper for cc.nvim with busted
local M = {}

-- Mock vim global for testing
vim = {
  fn = {
    termopen = function(cmd, opts)
      return 1 -- Mock job_id
    end,
    chansend = function(job_id, data)
      -- Mock implementation
    end,
    jobstop = function(job_id)
      -- Mock implementation
    end,
    jobwait = function(job_ids, timeout)
      -- Mock implementation - return array of job status
      local result = {}
      for _, job_id in ipairs(job_ids) do
        result[#result + 1] = -1 -- -1 means job is still running
      end
      return result
    end,
    readfile = function(path)
      local file = io.open(path, "r")
      if not file then
        error("File not found: " .. path)
      end
      local lines = {}
      for line in file:lines() do
        table.insert(lines, line)
      end
      file:close()
      return lines
    end,
    writefile = function(lines, path)
      local file = io.open(path, "w")
      if not file then
        error("Cannot write to file: " .. path)
      end
      for _, line in ipairs(lines) do
        file:write(line .. "\n")
      end
      file:close()
    end,
    bufnr = function(name)
      return name and 1 or 0
    end,
    getcwd = function()
      return "/test/cwd"
    end,
    getpos = function(mark)
      if mark == "'<" then
        return {0, 1, 1, 0}
      elseif mark == "'>" then
        return {0, 3, 10, 0}
      end
      return {0, 0, 0, 0}
    end,
    expand = function(expr)
      if expr == "%:p" then
        return "/test/current_file.lua"
      elseif expr == "<cword>" then
        return "testword"
      end
      return expr
    end,
    win_findbuf = function(buf)
      -- Mock implementation - return empty for most cases
      if buf == 1 then
        return {1}  -- Return one window for buffer 1
      end
      return {}
    end
  },
  api = {
    nvim_buf_get_lines = function(buf, start, end_line, strict)
      return {"line1", "line2", "line3"}
    end,
    nvim_buf_set_lines = function(buf, start, end_line, strict, lines)
      -- Mock implementation
    end,
    nvim_get_current_line = function()
      return "current line"
    end,
    nvim_create_buf = function(listed, scratch)
      return 1
    end,
    nvim_buf_is_valid = function(buf)
      return true
    end,
    nvim_buf_set_option = function(buf, option, value)
      -- Mock implementation
    end,
    nvim_buf_set_name = function(buf, name)
      -- Mock implementation
    end,
    nvim_open_win = function(buf, enter, config)
      return 1
    end,
    nvim_win_is_valid = function(win)
      return true
    end,
    nvim_win_close = function(win, force)
      -- Mock implementation
    end,
    nvim_win_set_option = function(win, option, value)
      -- Mock implementation
    end,
    nvim_buf_line_count = function(buf)
      return 10
    end,
    nvim_win_set_cursor = function(win, pos)
      -- Mock implementation
    end,
    nvim_set_current_line = function(line)
      -- Mock implementation
    end,
    nvim_create_namespace = function(name)
      return 1
    end,
    nvim_buf_add_highlight = function(buf, ns_id, hl_group, line, col_start, col_end)
      -- Mock implementation
    end,
    nvim_set_hl = function(ns_id, name, val)
      -- Mock implementation
    end,
    nvim_create_autocmd = function(event, opts)
      -- Mock implementation
    end,
    nvim_get_current_win = function()
      return 1
    end,
    nvim_win_get_buf = function(win)
      return 1
    end,
    nvim_win_set_buf = function(win, buf)
      -- Mock implementation
    end,
    nvim_win_set_width = function(win, width)
      -- Mock implementation
    end,
    nvim_win_set_height = function(win, height)
      -- Mock implementation
    end,
    nvim_get_current_buf = function()
      return 1
    end
  },
  split = function(str, sep)
    local lines = {}
    if str == "" then
      return {""}
    end
    
    local start = 1
    while true do
      local pos = str:find(sep or "\n", start)
      if not pos then
        table.insert(lines, str:sub(start))
        break
      end
      table.insert(lines, str:sub(start, pos - 1))
      start = pos + 1
    end
    
    return lines
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
  schedule = function(fn)
    fn()
  end,
  notify = function(msg, level)
    -- Mock implementation - silent for tests
  end,
  log = {
    levels = {
      INFO = 1,
      WARN = 2,
      ERROR = 3
    }
  },
  loop = {
    spawn = function(cmd, options, callback)
      -- Mock implementation - return mock handle
      return {
        stdio = {
          {write = function() end}, -- stdin
          {read_start = function() end}, -- stdout  
          {read_start = function() end}  -- stderr
        }
      }, "mock_pid"
    end,
    new_timer = function()
      return {
        start = function() end,
        stop = function() end,
        close = function() end
      }
    end,
    new_pipe = function(ipc)
      return {
        read_start = function(callback)
          -- Mock implementation
        end,
        write = function(data)
          -- Mock implementation
        end
      }
    end
  },
  cmd = function(cmd)
    -- Mock vim command execution
  end,
  wait = function(timeout, condition)
    -- Simple wait implementation for tests
    local start = os.clock()
    while os.clock() - start < timeout / 1000 do
      if condition and condition() then
        return true
      end
    end
    return false
  end,
  keymap = {
    set = function(mode, lhs, rhs, opts)
      -- Mock keymap setting
    end
  },
  o = {
    columns = 120,
    lines = 40
  }
}

-- Mock config for testing
_G.mock_config = {
  defaults = {
    claude_executable = "claude",
    auto_start = false,
    panel = {
      position = "right",
      size = 40,
      auto_resize = true,
      border = "rounded",
    },
    keymaps = {
      toggle_panel = "<leader>cc",
      send_file = "<leader>cf",
      send_selection = "<leader>cs",
    },
    highlights = {
      user_message = "Comment",
      claude_message = "String",
      system_message = "WarningMsg",
      error_message = "ErrorMsg",
    },
    timeout = 30000,
    max_history = 100,
  },
  options = {
    claude_executable = "claude",
    auto_start = false,
    panel = {
      position = "right",
      size = 40,
      auto_resize = true,
      border = "rounded",
    },
    keymaps = {
      toggle_panel = "<leader>cc",
      send_file = "<leader>cf",
      send_selection = "<leader>cs",
    },
    highlights = {
      user_message = "Comment",
      claude_message = "String",
      system_message = "WarningMsg",
      error_message = "ErrorMsg",
    },
    timeout = 30000,
    max_history = 100,
  },
  setup = function(opts)
    if opts then
      _G.mock_config.options = vim.tbl_deep_extend("force", _G.mock_config.defaults, opts)
    else
      _G.mock_config.options = vim.tbl_deep_extend("force", {}, _G.mock_config.defaults)
    end
  end,
  get = function(key)
    return _G.mock_config.options[key]
  end
}

-- Override config module
package.preload["cc_nvim.config"] = function()
  return _G.mock_config
end

-- Helper function to create temporary files
function M.create_temp_file(content)
  local temp_file = os.tmpname()
  local file = io.open(temp_file, "w")
  file:write(content)
  file:close()
  return temp_file
end

-- Helper function to clean up temporary files
function M.cleanup_temp_file(path)
  os.remove(path)
end

return M