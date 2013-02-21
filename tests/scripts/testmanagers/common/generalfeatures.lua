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
local os = os
--local agent.srvcon = require 'agent.srvcon'
--local Config = require 'Config'

local t = u.newtestsuite("general")
--local rpcclient

-- This script will tests the general features part

function t:setup()
end

function t.init(client)
  t.rpcclient = client
end

function t:teardown()

end

-- test the immediate connection while performing a synchronous connection to server
-- test details:
-- - force connection to server
-- - check that the device has really been connected to the server
function t:test_immediateconnection()
  t.rpcclient:call('require', 'agent.srvcon')
  --t.rpcclient:call('require', 'sched')
  --t.rpcclient:call('sched.run', 'agent.srvcon.connect')
--  assert_true(self.rpcclient:call('checklog', 'connection', 10))
end

-- test the plannified connection while performing a synchronous connection to server
-- test details:
-- - planify a connection within 30s (local datetime + 30s).
-- - check that no connection occurs before delay and that a connection has occured after 30s
function t:test_cron()
  local crontime = os.date()
  t.rpcclient:call('require', 'agent.srvcon')
--  t.rpcclient:call('require', 'sched')
--  t.rpcclient:call('sched.run', 'agent.srvcon.connect')
--  assert_true(t.rpcclient:call('checklog', 'unknown', 40))
end


function t:test_periodic()
  print("periodic")
  --Config.server.autoconnect = { period=1 }
  t.rpcclient:call('require', 'agent.srvcon')
  --t.rpcclient:call('require', 'sched')
  --t.rpcclient:call('sched.run', 'agent.srvcon.connect')
  --assert_true(t.rpcclient:call('checklog', 'connection',70))
  --assert_true(t.rpcclient:call('checklog', 'connection',70))
end

return t