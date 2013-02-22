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
local wsa        = require 'tests.webservicesaccess'
local u          = require 'unittest'
local rpc        = require 'rpc'
local logmanager = require 'tests.logmanager'
local os         = require 'os'

local t = u.newtestsuite("smsbearertest")
local rpcclient

function t.init(client)
  t.rpcclient = client
end

-- This script will tests the SMS bearer part

function t:setup()
  t.rpcclient:call('require', 'ServerConnector')
  t.rpcclient:call('require', 'tests.logmanager')
end



function t:teardown()
end


-- Perform a SMS Bearer test (command with notification)
-- test details:
-- - create the job on the server with notification. The SMS wakeup chain shall be defined in the model
-- - wait for a minute or two in order to receive the wakeup SMS.
-- - if SMS has been received and RA has been connected to server, result is OK otherwise test has failed.
function t:test_wakeupsms()
  local assetID = wsa.queryAsset()
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/asset/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:sendCommandRequest><ns:assets>"..assetID.."</ns:assets><ns:command><ns1:name>SoftwareUpdate</ns1:name><ns1:parameters><ns1:name>Value</ns1:name><ns1:stringValue>test</ns1:stringValue></ns1:parameters></ns:command></ns:sendCommandRequest></soapenv:Body></soapenv:Envelope>"

  t.rpcclient:call('require ', 'tests.libtests')
  t.rpcclient:call('TST_createassetSU')

  local jobnumber = wsa.createJob(request)
  print(jobnumber)

  wsa.getJobStatus(jobnumber)
  u.assert_not_nil(jobnumber, "Job ID is nil")
  u.assert_gt(0,jobnumber, "Job ID error")

  sched.wait(60)  -- wait 10 seconds in order to let the server process the job, then force connection to the server

  u.assert_true(t.rpcclient:call('TST_isassetupdated'), "AWTDA: asset not updated")
end