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

-- Extract script arguments
local strdate = os.date("%Y%m%d-%H%M%S")
local dirname = arg[1] or ("~/tests"..strdate)
local filter = arg[2] or "policy=OnCommit;target=linux_x86"
--local filter = arg[2] or "policy=OnCommit;target=linux_x86,linux_amd64"
--local filter = arg[2] or "policy=OnCommit"
--local filter = arg[2] or "target=linux_x86,linux_amd64, boxpro,"
--local filter = arg[2] or "policy=daily"
local testconfigfile = arg[3] or "defaulttestconfig"
local targetconfigfile = arg[4] or "defaulttargetconfig"

local function startup(dirname, filter, testconfigfile, targetconfigfile)

  if not arg[2] then
    print "No filter defined, running OnCommit tests as default"
  end

  -- display values that will be used in the program
  print("Using following parameters:")
  print("   - Working Directory: "..dirname)
  print("   - Filter: "..filter)
  print("   - Tests Config File: "..testconfigfile)
  print("   - Target Config File: "..targetconfigfile)

  local lfs = require 'lfs'

  -- create a new test manager according the provided parameters and then run it
  local testmanager = require 'tester.testmanager'
  local m = testmanager.new(dirname, filter, testconfigfile, targetconfigfile, lfs.currentdir())
  m:run()

  os.exit(0)
end

require 'sched'

sched.listen(4000)
sched.run(function() startup(dirname, filter, testconfigfile, targetconfigfile) end) --function() require "tester.init" end)
sched.loop() -- main loop: run the scheduler