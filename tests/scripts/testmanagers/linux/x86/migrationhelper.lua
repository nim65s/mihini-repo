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

-----------------------------------------------------------------
-- File: migrationhelper.lua
-- -- LINUX FILE --
-- Description:
--  This file performs tests on migration helper component
--      - without migration script
--      - with a lua migration script
--      - with a C migration script
-----------------------------------------------------------------
local sched      = require 'sched'
local wsa        = require 'tests.tools.webservicesaccess'
local u          = require 'unittest'
local rpc        = require 'rpc'
local logmanager = require 'tests.tools.logmanager'
local os         = require 'os'
local system     = require 'tests.tools.systemtest'
local lfs        = require 'lfs'
local agentsystem= require 'agent.system'

local t = u.newtestsuite("migrationhelperlinux")
local rpcclient

function t.init(client)
  t.rpcclient = client
end

function t:setup()
  t.rpcclient:call('require', 'tests.tools.logmanager')
end



function t:teardown()
end

-----------------------------------------------------------------
-- Method: assert_migrationexecution
-- Description:
--  This method executes the provided command and tries to read the standard output
--  of the agent. Then check if the result value matches with expected pattern.
-----------------------------------------------------------------
local function assert_migrationexecution(path, expectedtext)
  local status, oldpath = system.pexec("pwd")
  u.assert_not_nil(status)
  u.assert_equal(0, status)
  u.assert_not_nil(oldpath)

  local fd = system.popen("cd ".. path.." && ./bin/agent")
  u.assert_not_nil(fd, "File descriptor of migration script test is nil: "..path)
  local data = fd:read("*l")

  sched.wait(10)

  local client, err = rpc.newclient('localhost', 2012)
  u.assert_not_nil(client, err)

  -- exit ReadyAgent
  local result = client:call('os.exit', 0)

  sched.wait(2)

  u.assert_match(expectedtext, data, "Expected text of migration script not found")
  result = system.execute("cd "..oldpath)
end


-----------------------------------------------------------------
-- Method: test_withoutmigrationscript
-- Description:
--  This method tries to perform a migration without using migration script
--  The agent is compiled in a separated directory and started with a specific persist file containing
-- Scenario:
--    - Place the backup persist file
--    - Start the ReadyAgent and redirect ouput into a file.
--    - Wait for 30seconds
--    - Stop the Ready Agent
--    - Look for trace into the output file
-----------------------------------------------------------------
function t:test_withoutmigrationscript()
  -- copy the persist file into the new agent directory
  local result = system.execute("rm -f ../../specific/migrationwithout/runtime/persist/*.db")
  u.assert_not_nil(result)
  u.assert_equal(0, result, "Can't remove persisted files")
  sched.wait(1)
  -- start the special ReadyAgent and check expected value
  assert_migrationexecution("../../specific/migrationwithout/runtime", "GENERAL")

end


-----------------------------------------------------------------
-- Method: test_cmigrationscript
-- Description:
--  This method tries to perform a migration with a c migration script
--  The agent is compiled in a separated directory and started with a specific persist file containing
-- Scenario:
--    - Place the backup persist file
--    - Start the ReadyAgent and redirect ouput into a file.
--    - Wait for 30seconds
--    - Stop the Ready Agent
--    - Look for trace into the output file
-----------------------------------------------------------------
function t:test_cmigrationscript()
  -- copy the persist file into the new agent directory
  local result = system.execute("rm -f ../../specific/migrationc/runtime/persist/*.db")
  u.assert_not_nil(result)
  u.assert_equal(0, result, "Can't remove persisted files")
  sched.wait(1)
  -- start the special ReadyAgent with redirected output
  assert_migrationexecution("../../specific/migrationc/runtime", "MIGRATIONSCRIPT")
end


-----------------------------------------------------------------
-- Method: test_luamigrationscript
-- Description:
--  This method tries to perform a migration with a lua migration script
--  The agent is compiled in a separated directory and started with a specific persist file containing
-- Scenario:
--    - Place the backup persist file
--    - Start the ReadyAgent and redirect ouput into a file.
--    - Wait for 30seconds
--    - Stop the Ready Agent
--    - Look for trace into the output file
-----------------------------------------------------------------
function t:test_luamigrationscript()
  -- copy the persist file into the new agent directory
  local result = system.execute("rm -f ../../specific/migrationlua/runtime/persist/*.db")
  u.assert_not_nil(result)
  u.assert_equal(0, result, "Can't remove persisted files")
  sched.wait(1)
  -- start the special ReadyAgent with redirected output
  assert_migrationexecution("../../specific/migrationlua/runtime", "vfrom	unknown	vto")
end

return t