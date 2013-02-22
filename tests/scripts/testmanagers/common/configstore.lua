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

local t = u.newtestsuite("ConfigStore")
local rpcclient

function t.init(client)
  t.rpcclient = client
end

-- This script will tests the commands part

function t:setup()

end



function t:teardown()

end


-- read Node on an existing path
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_datareading()
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>ReadNode</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>config.server</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('require', 'srvcon')
  t.rpcclient:call('srvcon.connect')

  request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>ReadNode</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>config.server</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  jobnumber = wsa.createJob(request)
  t.rpcclient:call('require', 'agent.config')
  t.rpcclient:call('agent.config.default')

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('srvcon.connect')

end


-- read Node on an absent path
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_datawriting()
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>write</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>sys.config.mediation</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('require', 'ServerConnector')
  t.rpcclient:call('require', 'sched')
  t.rpcclient:call('sched.run', 'ServerConnector.connect')
  assert(t.rpcclient:call('checklog', 'unknown', 10))

  print("jobnumber :" .. jobnumber)
  --ServerConnector.connect()
end


-- perform a remote reboot on the device
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation (reboot)
-- - check results
function t:test_reboot()
  -- send job to restart the device and check execution
  --local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://m2mop.net/schema/ws/devicemgt/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest> <ns:device uniqueId=\"embeddedtests1337\"/><ns:command name=\"Reboot\"></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>Reboot</ns1:name></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('require', 'ServerConnector')
  t.rpcclient:call('require', 'sched')
  t.rpcclient:call('sched.run', 'ServerConnector.connect')
  assert(t.rpcclient:call('checklog', 'reboot', 10))


  print("jobnumber :" .. jobnumber)
  --ServerConnector.connect()
end

-- perform a remote reboot on the device
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation (reboot)
-- - check results
function t:test_unknown()
  -- send job to restart the device and check execution
  --local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://m2mop.net/schema/ws/devicemgt/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest> <ns:device uniqueId=\"embeddedtests1337\"/><ns:command name=\"Reboot\"></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>Unknown</ns1:name></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('require', 'ServerConnector')
  t.rpcclient:call('require', 'sched')
  t.rpcclient:call('sched.run', 'ServerConnector.connect')
  assert(t.rpcclient:call('checklog', 'unknown', 10))



  print("jobnumber :" .. jobnumber)
  --ServerConnector.connect()
end


return t