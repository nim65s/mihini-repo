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
-- File: applicationcontainer.lua
-- -- LINUX FILE --
-- Description:
--  This file performs tests on application container component (LINUX ONLY)
--      - installation of a lua application
--      - standard executable on Linux
--      - Application Monitor
--      - Application monitor app restart delay
-----------------------------------------------------------------
local sched      = require 'sched'
local u          = require 'unittest'
local rpc        = require 'rpc'
local os         = require 'os'
local system     = require 'tests.tools.systemtest'
--local system     = require 'agent.system'
local string     = string

local t = u.newtestsuite("applicationcontainerlinux")
local rpcclient

function t.init(client)
  t.rpcclient = client
end

function t:setup()
  -- retreive current user/group IDs
  local res, idstring = system.pexec("id")
  u.assert(res==0) --test used to be u.assert(res): to check
  local uid = string.gmatch(idstring, "uid=(%d+)")()
  local gid = string.gmatch(idstring, "gid=(%d+)")()

  --load appcon, and set a global in RA vm to acces to appcon API
  local fct_script = [[ global 'appcontest'; appcontest = require'agent.appcon']]
  local fct_tmp = t.rpcclient:newexec(fct_script)
  assert(fct_tmp, "Can't create remote function to load appcon")
  fct_tmp()

  -- start the appmon application (local directory is runtime/lua)
  system.popen("../bin/appmon_daemon -u ".. uid .." -g " .. gid)
end



function t:teardown()
  -- stop the appmon application
  system.execute("echo \"destroy\" | nc localhost 4242")

  --remove global in RA vm
  local fct_script = [[appcontest = nil]]
  local fct_tmp = t.rpcclient:newexec(fct_script)
  assert(fct_tmp, "Can't create remote function to clean appcon global")
  fct_tmp()

end


-----------------------------------------------------------------
-- Method: test_luaapplication
-- Description:
--  Install lua application
--  Restart the ReadyAgent
--  Check that application is running
--  Stop the application normally
--  Uninstall it
-----------------------------------------------------------------
function t:test_luaapplication()
  -- get the lua application directory
  local res, path = system.pexec("pwd")
  u.assert(res == 0) --test used to be u.assert(res): to check

  path = string.gsub(path, "\n", "")
  local apppath = path .. "/../externalapp/appconlua"

  -- install the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.install", "testluaapp", apppath, true))


  sched.wait(5)

  -- check that application is running
  u.assert_match(".status=%[STARTED%].", t.rpcclient:call("appcontest.status", "testluaapp"), "Application is not running")

  -- stop the application
  u.assert_match("^ok", t.rpcclient:call("appcontest.stop", "testluaapp"), "Cannot stop application")

  -- uninstall the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.uninstall", "testluaapp"), "Cannot uninstall application")

  u.assert(0 == system.execute("cd " .. path))
end


-----------------------------------------------------------------
-- Method: test_crashluaapplication
-- Description:
--  Install lua application
--  Restart the ReadyAgent
--  Make the Lua app die with some error, check it is restarted
--  Stop the application normally
--  Uninstall it
-----------------------------------------------------------------
function t:test_crashluaapplication()
  -- get the lua application directory
  local res, path = system.pexec("pwd")
  u.assert(res == 0 ) --test used to be u.assert(res): to check

  path = string.gsub(path, "\n", "")
  local apppath = path .. "/../externalapp/appconcrashlua"
  system.execute("touch "..apppath.."/toto")

  -- install the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.install", "testcrashluaapp", apppath, true))


  sched.wait(15)

  -- check that application is running (status "STARTED"). So the application has exited with -1 status code first time and has been restarted correctly
  u.assert_match(".status=%[STARTED%].", t.rpcclient:call("appcontest.status", "testcrashluaapp"), "Application is not running")

  -- stop the application
  u.assert_match("^ok", t.rpcclient:call("appcontest.stop", "testcrashluaapp"), "Cannot stop application")

  -- uninstall the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.uninstall", "testcrashluaapp"), "Cannot uninstall application")

  u.assert(0 == system.execute("cd " .. path))
end


-----------------------------------------------------------------
-- Method: test_standardmonitor
-- Description:
--  Use a standard application
-----------------------------------------------------------------
function t:test_standardmonitor()
  -- get the lua application directory
  local res, path = system.pexec("pwd")
  u.assert(res == 0)

  path = string.gsub(path, "\n", "")
  local apppath = path .. "/../externalapp/appconsh"

  -- install the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.install", "testshapp", apppath, true))

  sched.wait(5)

  -- check that application is running
  u.assert_match(".status=%[STARTED%].", t.rpcclient:call("appcontest.status", "testshapp"), "Application is not running")

  -- stop the application
  u.assert_match("^ok", t.rpcclient:call("appcontest.stop", "testshapp"), "Cannot stop application")

  -- uninstall the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.uninstall", "testshapp"), "Cannot uninstall application")

  u.assert(0 == system.execute("cd " .. path))
end


-----------------------------------------------------------------
-- Method: test_standardcatchsigterm
-- Description:
-----------------------------------------------------------------
function t:test_standardcatchsigterm()
  -- get the lua application directory
  local res, path = system.pexec("pwd")
  u.assert(res == 0)

  path = string.gsub(path, "\n", "")
  local apppath = path .. "/../externalapp/appconshcatchsigterm"

  -- install the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.install", "testcatchsigtermshapp", apppath, true))

  sched.wait(5)

  -- check that application is running
  u.assert_match(".status=%[STARTED%].", t.rpcclient:call("appcontest.status", "testcatchsigtermshapp"), "Application is not running")

  -- stop the application
  u.assert_match("^ok", t.rpcclient:call("appcontest.stop", "testcatchsigtermshapp"), "Cannot stop application")

  -- uninstall the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.uninstall", "testcatchsigtermshapp"), "Cannot uninstall application")

  u.assert(0 == system.execute("cd " .. path))
end


-----------------------------------------------------------------
-- Method: test_standardignoresigterm
-- Description:
-----------------------------------------------------------------
function t:test_standardignoresigterm()
  -- get the lua application directory
  local res, path = system.pexec("pwd")
  u.assert(res == 0)

  path = string.gsub(path, "\n", "")
  local apppath = path .. "/../externalapp/appconshignoresigterm"

  -- install the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.install", "testignoresigtermshapp", apppath, true))

  sched.wait(5)

  -- check that application is running
  u.assert_match(".status=%[STARTED%].", t.rpcclient:call("appcontest.status", "testignoresigtermshapp"), "Application is not running")

  -- stop the application
  u.assert_match("^ok", t.rpcclient:call("appcontest.stop", "testignoresigtermshapp"), "Cannot stop application")

  -- uninstall the lua application
  u.assert_equal("ok", t.rpcclient:call("appcontest.uninstall", "testignoresigtermshapp"), "Cannot uninstall application")

  u.assert(0 == system.execute("cd " .. path))
end


return t