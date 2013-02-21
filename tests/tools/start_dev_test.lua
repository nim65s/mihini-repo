#!bin/lua

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

local AGENT_DIR = nil
local env = nil
local depmodule = nil

local function depsync()
   if depmodule then
      sched.wait("module", "done")
   end
end

local function run_lua_unittest(testname)
   depsync()
   testname = testname:gsub(".lua", "")
   require ("tests." .. testname)
   unittest.run()

   local status = (#unittest.getStats().failedtests ~= 0) and 1 or 0
   os.exit(status)
end

local function run_native_unittest(testname)
   depsync()
   local status = os.execute("env - " .. env .. " " .. AGENT_DIR .. "/bin/" .. testname)
   os.exit(status)
end

local function loadtestwrappermodule(module)
   require ("testwrapperfwk." .. module)
end

local function envsetup(progname)
   local fd = io.popen("cd $(dirname ".. progname .. ") && pwd")
   AGENT_DIR=fd:read('*l')
   fd:close()

   -- Unfortunately os.setenv() does not exist in standard Lua
   local LUA_PATH = AGENT_DIR .. "/?.lua;" .. AGENT_DIR .. "/lua/?.lua;" .. AGENT_DIR .. "/lua/?/init.lua"
   local LUA_CPATH = AGENT_DIR .. "/lua/?.so"
   env = "LD_LIBRARY_PATH=" .. AGENT_DIR .. "/lib"
   env = env .. " LUA_PATH=\"" .. LUA_PATH .. "\""
   env = env .. " LUA_CPATH=\"" .. LUA_CPATH .. "\""

   if os.getenv("SWI_LOG_VERBOSITY") then
      env = env .. " SWI_LOG_VERBOSITY=" .. os.getenv("SWI_LOG_VERBOSITY")
   end

   package.path = LUA_PATH
   package.cpath = LUA_CPATH

   package.loaded.testwrapperfwk = {}
   package.loaded["testwrapperfwk"].run_unittest_task = true
end

local function usage()
   print("Usage: " .. arg[0] .. " [ -l name ] unittest")
   os.exit(1)
end

local function main(argv)
   if #argv < 1 then
      usage()
   end
   envsetup(argv[0])
   depmodule = (argv[1] == "-l") and argv[2] or nil

   local testname = depmodule and argv[3] or argv[1]
   local from, to = string.find(testname, ".lua")
   local routine = (not from and not to) and run_native_unittest or run_lua_unittest
   local sched = require 'sched'
   
   if depmodule then
      loadtestwrappermodule(depmodule)
   end
   if package.loaded["testwrapperfwk"].run_unittest_task then
      sched.run(routine, testname)
   end
   sched.loop()
end

main(arg)
