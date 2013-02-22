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

local wsa = require 'tests.tools.webservicesaccess'
local u = require 'unittest'
local logmanager = require 'tests.tools.logmanager'


local t = u.newtestsuite("logstore")

-- This script will tests the logstore features part
function t:setup()
  t.rpcclient:call('require', 'tests.embeddedlogstore')
  t.rpcclient:call('testlog_setup')
end

function t.init(client)
  t.rpcclient = client
end

function t:teardown()
  t.rpcclient:call('testlog_teardown')
end


-- start the ready agent
local function runspecificagent(path, logpolicy, testname)

  local res = system.execute("cd ".. path.." && ./bin/agent")
  u.assert_equal(0, res, "File descriptor of ReadyAgent is nil: "..path)

  sched.wait(2)

  local client, err = rpc.newclient('localhost', 2012)
  u.assert_not_nil(client, err)

  -- Set the policy name and restart the ReadyAgent
  local result = client:call('require', 'tests.embeddedlogstore')
  u.assert_not_nil(result)

  client:call('setlogpolicy', logpolicy)
  client:call('os.exit', 0) -- exit ReadyAgent

  -- restart the ReadyAgent
  sched.wait(2)
  local res = system.execute("cd ".. path.." && ./bin/agent")
  u.assert_equal(0, res, "File descriptor of ReadyAgent is nil: "..path)

  sched.wait(2)

  client, err = rpc.newclient('localhost', 2012)
  u.assert_not_nil(client, err)

  -- call the procedure to generate logs on the device
  result = client:call('require', 'tests.embeddedlogstore')
  u.assert_not_nil(result)
  u.assert(client:call(testname), "Test of "..logpolicy.." failed")

end

-- Fill the memory with a huge quantity of logs
function t:test_biglogs()
  --runspecificagent("./", 'context', 'testlog_biglogs')
  t.rpcclient:call('setlogpolicy', 'buffered_all')
  --t.rpcclient:call('testlog_biglogs')

--  assert_true(self.rpcclient:call('checklog', 'connection', 10))
end

-- test the immediate connection while performing a synchronous connection to server
-- test details:
-- - force connection to server
-- - check that the device has really been connected to the server
function t:test_context()
  t.rpcclient:call('setlogpolicy', 'context')
  t.rpcclient:call('testlog_context')
  --t.rpcclient:call(Config.log.policy.name = "context"

--  t.rpcclient:call('require', 'sched')
--  t.rpcclient:call('sched.run', 'ServerConnector.connect')
--  assert_true(self.rpcclient:call('checklog', 'connection', 10))
end

-- test the plannified connection while performing a synchronous connection to server
-- test details:
-- - planify a connection within 30s (local datetime + 30s).
-- - check that no connection occurs before delay and that a connection has occured after 30s
function t:test_sole()
  t.rpcclient:call('setlogpolicy', 'sole')
  t.rpcclient:call('testlog_sole')

--  t.rpcclient:call('require', 'ServerConnector')
--  t.rpcclient:call('require', 'sched')
--  t.rpcclient:call('sched.run', 'ServerConnector.connect')
--  assert_true(t.rpcclient:call('checklog', 'unknown', 40))
end


function t:test_bufferedall()
  t.rpcclient:call('setlogpolicy', 'buffered_all')
  t.rpcclient:call('testlog_bufferedall')

  --Config.server.autoconnect = { period=1 }
--  t.rpcclient:call('require', 'ServerConnector')
  --t.rpcclient:call('require', 'sched')
  --t.rpcclient:call('sched.run', 'ServerConnector.connect')
  --assert_true(t.rpcclient:call('checklog', 'connection',70))
  --assert_true(t.rpcclient:call('checklog', 'connection',70))
end

return t