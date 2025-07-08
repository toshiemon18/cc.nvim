#!/usr/bin/env lua

-- Simple test runner for cc.nvim
local function run_tests()
  -- Set up package path
  package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"
  
  local test_files = {
    "tests/cc_nvim/config_spec.lua",
    "tests/cc_nvim/utils_spec.lua", 
    "tests/cc_nvim/claude_spec.lua",
    "tests/cc_nvim/parser_spec.lua"
  }
  
  -- Load spec helper
  require("tests.cc_nvim.spec_helper")
  
  -- Simple test framework
  local total_tests = 0
  local passed_tests = 0
  local failed_tests = 0
  
  -- Test context
  local current_describe = ""
  local current_it = ""
  
  -- Global test functions
  function describe(description, fn)
    current_describe = description
    print("\n" .. description)
    fn()
  end
  
  function it(description, fn)
    current_it = description
    total_tests = total_tests + 1
    
    -- Run before_each if it exists
    if _G._before_each then
      local success, err = pcall(_G._before_each)
      if not success then
        failed_tests = failed_tests + 1
        print("  ✗ " .. description)
        print("    Error in before_each: " .. tostring(err))
        return
      end
    end
    
    local success, err = pcall(fn)
    if success then
      passed_tests = passed_tests + 1
      print("  ✓ " .. description)
    else
      failed_tests = failed_tests + 1
      print("  ✗ " .. description)
      print("    Error: " .. tostring(err))
    end
  end
  
  function before_each(fn)
    -- Simple before_each implementation
    _G._before_each = fn
  end
  
  -- Assertion functions
  local assert_mt = {}
  
  function assert_mt:equal(actual, expected)
    if actual ~= expected then
      error(string.format("Expected %s but got %s", tostring(expected), tostring(actual)))
    end
  end
  
  function assert_mt:are_equal(expected, actual)
    return self:equal(expected, actual)
  end
  
  function assert_mt:same(actual, expected)
    -- Simple table comparison
    if type(actual) == "table" and type(expected) == "table" then
      for k, v in pairs(actual) do
        if expected[k] ~= v then
          error(string.format("Tables differ at key %s: expected %s but got %s", tostring(k), tostring(expected[k]), tostring(v)))
        end
      end
      for k, v in pairs(expected) do
        if actual[k] ~= v then
          error(string.format("Tables differ at key %s: expected %s but got %s", tostring(k), tostring(v), tostring(actual[k])))
        end
      end
    elseif actual ~= expected then
      error(string.format("Expected %s but got %s", tostring(expected), tostring(actual)))
    end
  end
  
  function assert_mt:is_true(value)
    if value ~= true then
      error("Expected true but got " .. tostring(value))
    end
  end
  
  function assert_mt:is_false(value)
    if value ~= false then
      error("Expected false but got " .. tostring(value))
    end
  end
  
  function assert_mt:is_nil(value)
    if value ~= nil then
      error("Expected nil but got " .. tostring(value))
    end
  end
  
  function assert_mt:is_not_nil(value)
    if value == nil then
      error("Expected non-nil value but got nil")
    end
  end
  
  function assert_mt:has_no_errors(fn)
    local success, err = pcall(fn)
    if not success then
      error("Expected no errors but got: " .. tostring(err))
    end
  end
  
  -- Create assert table with proper method access
  local assert_table = {
    are = {
      equal = function(actual, expected) return assert_mt:equal(actual, expected) end,
      same = function(actual, expected) return assert_mt:same(actual, expected) end
    },
    is = {
      is_true = function(actual) return assert_mt:is_true(actual) end,
      is_false = function(actual) return assert_mt:is_false(actual) end,
      is_nil = function(actual) return assert_mt:is_nil(actual) end,
      is_not_nil = function(actual) return assert_mt:is_not_nil(actual) end
    },
    has_no = { errors = function(fn) return assert_mt:has_no_errors(fn) end }
  }
  
  -- Add direct access methods for syntax like assert.is_nil
  assert_table.is_true = function(actual) return assert_mt:is_true(actual) end
  assert_table.is_false = function(actual) return assert_mt:is_false(actual) end
  assert_table.is_nil = function(actual) return assert_mt:is_nil(actual) end
  assert_table.is_not_nil = function(actual) return assert_mt:is_not_nil(actual) end
  
  -- Add stub method for assert.stub() syntax
  assert_table.stub = function(stub_target)
    -- Return the stub_target itself, which should have .was property
    return stub_target
  end
  
  _G.assert = assert_table
  
  -- Stub function for mocking
  function stub(obj, method, replacement)
    local original = obj and obj[method]
    local call_count = 0
    local call_args = {}
    
    local stub_fn = replacement or function(...)
      call_count = call_count + 1
      call_args[call_count] = {...}
    end
    
    -- Add was property to the stub function
    stub_fn.was = {
      called = function()
        return call_count > 0
      end,
      called_with = function(...)
        local expected_args = {...}
        for i, args in ipairs(call_args) do
          local match = true
          for j, expected in ipairs(expected_args) do
            if args[j] ~= expected then
              match = false
              break
            end
          end
          if match then
            return true
          end
        end
        return false
      end
    }
    
    if obj then
      obj[method] = stub_fn
    end
    
    local stub_obj = {
      was = stub_fn.was,
      restore = function()
        if obj and original then
          obj[method] = original
        end
      end
    }
    
    return stub_obj
  end
  
  _G.stub = stub
  
  -- Run all test files
  for _, test_file in ipairs(test_files) do
    print("\n=== Running " .. test_file .. " ===")
    
    local success, err = pcall(dofile, test_file)
    if not success then
      print("Error loading test file: " .. tostring(err))
      failed_tests = failed_tests + 1
    end
  end
  
  -- Print summary
  print("\n=== Test Summary ===")
  print(string.format("Total: %d, Passed: %d, Failed: %d", total_tests, passed_tests, failed_tests))
  
  if failed_tests > 0 then
    os.exit(1)
  else
    print("All tests passed!")
    os.exit(0)
  end
end

-- Run the tests
run_tests()