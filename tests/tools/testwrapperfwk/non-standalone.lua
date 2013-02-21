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

local sched  = require 'sched'
local testwrapperfwk = require 'testwrapperfwk'

local function run_remote_unit_test(testname)
   local rpc = require 'rpc'
   testname = testname:gsub(".lua", "")

   local client = rpc.newclient()
   if not client then
      print("Ready agent not started")
      return
   end

   local run_unit_test = client:newexec(function(testname)
					   require ('tests.'..testname)
					   unittest.run()
					   local status = (#unittest.getStats().failedtests ~= 0) and 1 or 0
					   return status
					end)
   local status = run_unit_test(testname)
   os.exit(status)
end

testwrapperfwk.run_unittest_task = false
sched.run(run_remote_unit_test, arg[3])
