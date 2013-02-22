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
-- File: datapersistence.lua
-- Description:
--  This file perform tests on data persistence on the following cases:
--      - data persistence on data arrival
--      - data persistence before shutdown
--      - data persistence before reboot
-----------------------------------------------------------------
local wsa        = require 'tests.tools.webservicesaccess'
local u          = require 'unittest'
local sched      = require 'sched'
local rpc        = require 'rpc'
local logmanager = require 'tests.tools.logmanager'
local os         = require 'os'
--local system     = require 'agent.system'
local system = require 'tests.tools.systemtest'

local t = u.newtestsuite("persistence")
local rpcclient

function t.init(client)
  t.rpcclient = client
end

-- This script will tests the commands part

function t:setup()
  t.rpcclient:call('require', 'agent.srvcon')
  t.rpcclient:call('require', 'tests.tools.logmanager')
end



function t:teardown()
end


function t:test_ondataarrival()
  -- register jobs on the server
  -- create a job of command on the asset
  --local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>ReadNode</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>emptypathtest</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  --local jobnumber = wsa.createJob(request)

  -- create a job of datawriting on a data in the asset


  --start the lua sample on the embedded side
  --sched.wait(10)  -- wait 10 seconds in order to let the server process the jobs
  --t.rpcclient:call('require','tests.awtdaembsample')
  --local result = t.rpcclient:call('awtdarunsample')

  --u.assert_not_nil(result)
  --u.assert_equal(1, result, "AWTDA lua sample")

end

function t:test_beforeshutdown()
  --local result = nil
  --local result = system.pexec("")

  --t.rpcclient:call("os.shutdown")
  --u.assert_not_nil(result)
  --u.assert_equal(0, result)
end

function t:test_beforereboot()
  --local result = nil
  --local result = system.pexec("")

  --t.rpcclient:call("os.reboot")

  --u.assert_not_nil(result)
  --u.assert_equal(0, result)
end

return t