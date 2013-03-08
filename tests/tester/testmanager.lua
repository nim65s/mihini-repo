-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local targetmanager = require 'tester.targetmanager'
local print = print
local p = p
local string = string
local copcall = copcall
local table = table
local pairs = pairs
local ipairs = ipairs
local require = require
local setmetatable = setmetatable

module(...)
local managerapi = {}

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

-- Function: tablesearch
-- Description: search for the provided value in the elements of the table.
-- Return: the index of the value in the table if found, nil otherwise
local function tablesearch(t, value)
  for i,v in ipairs(t) do
    if v == value then return i end
  end

  -- not found, return nil
  return nil
end


--------------------------------------------------------------------------------
-- Config Management
--------------------------------------------------------------------------------
-- Function: filterpolicy
-- Description: filter the input table according to the provided policy
-- Return: the new table containing only tests that respect the policy
--         if policy is empty, then return the exact table
local function filterpolicy(t, policy)
  if not policy then return t end

  local l_t = {}

  for k,v in pairs(t) do
    if string.lower(v.TestPolicy) == policy then l_t[k] = v end
  end

  return l_t
end

-- Function: parseFilter
-- Description: load the config file and compute a table containing all tests to run according to the filter
-- Return: A table containing only tests that respect the filter and organized by targets
local function parseFilter(filter)
  local l_filters = {}

  filter = string.lower(filter)

  -- extract target names
  local l_targets = filter:match("target=([^;]+);?$?")
  l_filters.targets = {}
  if l_targets then
    for target in l_targets:gmatch("([^,]+),?$?") do
      table.insert(l_filters.targets, target:match("%S+"))
    end
  end

  -- extract policy name
  local l_policy = filter:match("policy=([^;]+);?$?")
  if l_policy then l_policy = l_policy:match("%S+") end
  l_filters.policy = l_policy

  return l_filters
end

-- Function: loadconfig
-- Description: load the config file and compute a table containing all tests to run according to the filter
-- Return: A table containing only tests that respect the filter and organized by targets
local function loadconfig(testconfigfile, targetconfigfile, filter)
  print('loading config files:')
  print('--tests list definition: '..testconfigfile)
  print('--targets list definition: '..targetconfigfile)
  local l_testconfig = require('tester.'..testconfigfile)
  local l_targetconfig = require('tester.'..targetconfigfile)
  local l_filter = {}


  l_filter = parseFilter(filter)
  l_testconfig = filterpolicy(l_testconfig, l_filter.policy)

  local l_finalconfig = {}

  -- if no targets have been specified, then list all available targets in the table
  if (not l_filter.targets) or (#l_filter.targets == 0) then
    l_filter.targets = {}
    for k,v in pairs(l_testconfig) do
      for i, targetname in ipairs(v.target) do
        if not tablesearch(l_filter.targets, targetname) then table.insert(l_filter.targets, targetname) end
      end
    end
  end

  -- loop on all values of the target filter to fill the result table
  for tarkey,target in ipairs(l_filter.targets) do
    if not l_finalconfig[target] then l_finalconfig[target] = {} end

    -- insert the config table in the target configuration
    l_finalconfig[target].config = {}
    l_finalconfig[target].config = l_targetconfig[target]
    l_finalconfig[target].tests = {}
    for k,v in pairs(l_testconfig) do
      local l_index = tablesearch(v.target, target)
      if l_index then
        print("Adding ".. k .. " to target: "..target)
        table.insert(l_finalconfig[target].tests, k)
      end
    end
  end

  return l_finalconfig
end

--------------------------------------------------------------------------------
-- Display Management
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Target Management
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Tests Management
--------------------------------------------------------------------------------

-- Function: runluafwktests
-- Description: Create a new test manager, according to the specified filter and config files
-- Return: the instance of the new test manager
local function runluafwktests(target)
  print("	Running luafwk tests")
  target:install()

  target:start()
  target:stop()
end

-- Function: runagenttests
-- Description: Create a new test manager, according to the specified filter and config files
-- Return: the instance of the new test manager
local function runagenttests(target)
  print("	Running agent tests")
  target:install()

  target:start()
  target:stop()
end

-- Function: runhosttests
-- Description: Create a new test manager, according to the specified filter and config files
-- Return: the instance of the new test manager
local function runhosttests(target)
  print("	Running host tests")
  target:install()

  target:start()
  target:stop()
end

-- Function: new
-- Description: Create a new test manager, according to the specified filter and config files
-- Return: the instance of the new test manager
function new(svndir, filter, testconfigfile, targetconfigfile, testdir)
  local instance = setmetatable({ svndir = svndir,
      filter = filter,
      testconfigfile = testconfigfile,
      targetconfigfile = targetconfigfile,
      testdir = testdir}, {__index=managerapi})

  instance.tests = loadconfig(testconfigfile, targetconfigfile, filter)

  return instance
end


-- Function: runtarget
-- Description: Run the test suites on the specified target
-- Return: none
function managerapi:runtarget(target)
  target:compile()
  runluafwktests(target)
  runagenttests(target)
  runhosttests(target)

  return "success"
end

-- Function: run
-- Description: Run the test suites using the configured ones
-- Return: none
function managerapi:run()
  -- loop on all targets configured for the tests to play
  for key, value in pairs(self.tests) do
    print("Running tests on target: " .. key)

      -- create a new target manager for the current target
      local l_target = targetmanager.new('tester.config'..key, value, self.svndir, self.testdir.."/../../targets/"..key)

      --protect the test run for this target
      local res, error = copcall(function() self:runtarget(l_target) end )
      if not res then print(error) end

      print("end of target "..key)
  end

  print("end of run")
end