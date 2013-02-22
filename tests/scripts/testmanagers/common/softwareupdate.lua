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

local t = u.newtestsuite("sotfwareupdate")

function t.init(client)
  t.rpcclient = client
end

-- This script will tests the software update part

function t:setup()
  t.rpcclient:call('require', 'agent.srvcon')
  t.rpcclient:call('require', 'tests.tools.logmanager')
end



function t:teardown()
end


-- Perform a software update using AWTDA
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_updateAWTDA()
--   local assetID = wsa.queryAsset()
--   local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/asset/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:assets>"..assetID.."</ns:assets><ns:command><ns1:name>SoftwareUpdate</ns1:name><ns1:parameters><ns1:name>Value</ns1:name><ns1:stringValue>test</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
--
--   t.rpcclient:call('require ', 'tests.tools.libtests')
--   u.assert_true(t.rpcclient:call('TST_createassetSU'))
--
--   local jobnumber = wsa.createJob(request)
--
--   u.assert_not_nil(jobnumber, "Job ID is nil")
--   u.assert_gt(0,jobnumber, "Job ID error")
--
--   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
--   t.rpcclient:call('agent.srvcon.connect')
--   sched.wait(20)  -- wait 20 seconds in order to let the server process the job, then force connection to the server
--
--   u.assert_true(t.rpcclient:call('TST_isassetupdated'), "AWTDA: asset not updated, job number is ".. jobnumber)
end


-- perform a local update
-- test details:
-- - Put the update script in the update folder
-- - force the device to update
-- - check results
function t:test_localupdate()
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>ReadNode</ns1:name><ns1:parameters><ns1:name>path</ns1:name><ns1:stringValue>emptypathtest</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('setLogFilter', 'emptypathtest not found')
  t.rpcclient:call('agent.srvcon.connect')
  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  u.assert_true(t.rpcclient:call('checkfilter'), "empty path tests failed")

end


-- perform a software update using OMADM
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_updateOMADM()
--   -- send job to restart the device and check execution

  --todo
   local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>Unknown</ns1:name></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
   local jobnumber = wsa.createJob(request)
--
   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
--   t.rpcclient:call('setLogFilter', 'Unknown')
   t.rpcclient:call('agent.srvcon.connect')
--   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
   u.assert_true(t.rpcclient:call('checkfilter'))
end

-- perform a software update using OMADM and HTTPS
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_updateOMADMS()
--   -- send job to restart the device and check execution
--   local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>Unknown</ns1:name></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
--   local jobnumber = wsa.createJob(request)
--
--   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
--   t.rpcclient:call('setLogFilter', 'Unknown')
--   t.rpcclient:call('agent.srvcon.connect')
--   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
--   u.assert_true(t.rpcclient:call('checkfilter'))
end

-- perform a software update targeting an asset
-- test details:
-- - create the job on the server
-- - force the device to connect to the server
-- - wait for a few seconds in order to let the device perform the operation
-- - check results
function t:test_updateAsset()
--   -- send job to restart the device and check execution
--   local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:devices>embeddedtests1337</ns:devices><ns:command><ns1:name>Unknown</ns1:name></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"
--   local jobnumber = wsa.createJob(request)
--
--   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
--   t.rpcclient:call('setLogFilter', 'Unknown')
--   t.rpcclient:call('agent.srvcon.connect')
--   sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
--   u.assert_true(t.rpcclient:call('checkfilter'))
end

function t:test_DataWriting()
  -- create the datawriting job on the server
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:writeDataRequest><ns:devices>embeddedtests1337</ns:devices><ns:parameters><ns1:name>Version</ns1:name><ns1:path>/update.swlist</ns1:path><ns1:stringValue>toto</ns1:stringValue></ns:parameters></ns:writeDataRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('agent.srvcon.connect')
end


function t:test_DataReading()
  -- create the datareading job on the server
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/device/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:writeDataRequest><ns:devices>embeddedtests1337</ns:devices><ns:parameters><ns1:name>Version</ns1:name><ns1:path>/update.swlist</ns1:path><ns1:stringValue>toto</ns1:stringValue></ns:parameters></ns:writeDataRequest></soapenv:Body></soapenv:Envelope>"
  local jobnumber = wsa.createJob(request)

  sched.wait(10)  -- wait 10 seconds in order to let the server process the job, then force connection to the server
  t.rpcclient:call('agent.srvcon.connect')
end

return t