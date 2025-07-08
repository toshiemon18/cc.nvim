-- Test helper for cc.nvim
local M = {}

-- Mock vim global for testing
if not vim then
  vim = {
    fn = {
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
        if expr == "<cword>" then
          return "testword"
        end
        return expr
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
      print(msg)
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
        return nil, "spawn not implemented in test"
      end,
      new_timer = function()
        return {
          start = function() end,
          stop = function() end,
          close = function() end
        }
      end,
      new_pipe = function()
        return {
          read_start = function() end,
          write = function() end
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
    end
  }
end

-- Mock package.path for testing
if not package.path:match("lua/?.lua") then
  package.path = package.path .. ";lua/?.lua;lua/?/init.lua"
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

-- Helper function to mock require
function M.mock_require(module_name, mock_table)
  local original_require = require
  _G.require = function(name)
    if name == module_name then
      return mock_table
    end
    return original_require(name)
  end
  
  return function()
    _G.require = original_require
  end
end

return M