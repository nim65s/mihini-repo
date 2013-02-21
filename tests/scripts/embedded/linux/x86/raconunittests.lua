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

local sched = require 'sched'
local u = require 'unittest'
local t = u.newtestsuite("raconunittest")

local function ctest_run_unittest(testname)
   local fd = io.popen("cd .. && ctest --output-on-failure --timeout 16 -R " .. testname)
   while true do
      local line = fd:read("*l")
      if not line then break end
      print(line)
   end
   local status = fd:close()
   return status
end

function t :setup()
   print("Running embedded racon unit tests")
end

function t :teardown()
   print("Finishing embedded racon unit tests")
end

function t :test_Lua_modules()
   assert( ctest_run_unittest("'[a-z_]+.lua'")  == 0)
end

function t :test_C_modules()
   assert( ctest_run_unittest("'[a-z_]+test'") == 0)
end

return t
