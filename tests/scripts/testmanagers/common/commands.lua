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

local sched      = require 'sched'
local wsa        = require 'tests.tools.webservicesaccess'
local u          = require 'unittest'
local rpc        = require 'rpc'
local logmanager = require 'tests.tools.logmanager'
local os         = require 'os'

local t = u.newtestsuite("commands")

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


-- read Node on an existing path
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_readexistingnode()
  local date = os.date('*t')
  date.min = date.min-3  -- robustness (3 minutes delay)
  if (date.min < 0) then
    date.min = date.min + 60
    date.hour = date.hour - 1
  end
  if date.hour < 0 then date.hour = 0; date.min = 0 end

  local strdate = "".. date.year .. "-".. string.format("%02d", date.month).."-".. string.format("%02d", date.day) .."T"..string.format("%02d", date.hour)..":"..string.format("%02d", (date.min-3))..":00"
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>ReadNode</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>config.server</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local requestresult = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/device/criteria/1.0/\" xmlns:ns2=\"http://www.sierrawireless.com/airvantage/schema/api/data/criteria/1.0/\" xmlns:ns3=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:queryDataRequest><ns:criteria><ns1:device>embeddedtests1337</ns1:device><ns1:variableName>port</ns1:variableName><ns1:variablePath>/config/server</ns1:variablePath><ns1:date from=\""..strdate.."\"/></ns:criteria><ns:pagination start=\"0\" count=\"1\"/></ns:queryDataRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(60)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('agent.srvcon.connect')
  sched.wait(60)  -- wait 20 seconds in order to let the server process the job, then force connection to the server
  local res = wsa.queryData(requestresult)
  u.assert_not_nil(res, "Cannot found an updated variable 'path' in path '/config/server' with last update after "..strdate)
  u.assert_not_nil(res.attr, "Existing Node not read") -- there is a recorded value
end


-- read Node on an absent path
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_readAbsentNode()
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>ReadNode</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>emptypathtest</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('setLogFilter', 'emptypathtest not found')
  t.rpcclient:call('agent.srvcon.connect')
  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  u.assert(t.rpcclient:call('checkfilter'))

end


-- perform a remote reboot on the device
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation (reboot)
-- - check results
function t:test_unknown()
  -- send job to restart the device and check execution
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>Unknown</ns1:name></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('setLogFilter', 'Unknown')
  t.rpcclient:call('agent.srvcon.connect')
  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  u.assert_true(t.rpcclient:call('checkfilter'))
end


return t
