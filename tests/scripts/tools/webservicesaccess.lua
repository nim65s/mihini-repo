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

local soap_client = require "tests.tools.client"
local soap        = require "tests.tools.soap"
local socket_http = require("socket.http")
local ltn12       = require "ltn12"
local pathutils       = require "utils.path"
local tableutils       = require "utils.table"
local print       = print
local table       = table
local string      = string
local p           = p
local ipairs      = ipairs
local type        = type
local u           = require 'unittest'

module(...)

-- device management: http://webplt-m2m.anyware-tech.com/ws/deviceManagement.wsdl
-- asset management: http://webplt-m2m.anyware-tech.com/ws/assetManagement.wsdl
-- event management: http://webplt-m2m.anyware-tech.com/ws/eventManagement.wsdl
-- settings management: http://webplt-m2m.anyware-tech.com/ws/settingsManagement.wsdl
local backendURL

local request = {
  --url = "http://webplt-m2m.anyware-tech.com",
  --url = "http://embeddedtests:embeddedtests@webplt-m2m.anyware-tech.com/portal/soap",
  url = "http://webplt-m2m.anyware-tech.com/portal/soap",
  soapaction = "",
  soapversion = 1.1,
  namespace = "http://www.sierrawireless.com/airvantage/schema/ws/asset/1.0/",
  method = "",
  entries = {
    {
      tag = "getAvailableCommandsRequest",
      {tag="asset", 2254}
    }
  }
}

-- Perform the Http Request (body) to the provided url.
-- Returns the HTTP response
local function doHttpRequest(url, body)
    local respBody = {}
    local headers =
    {
        ["Authorization"] = "Basic ZW1iZWRkZWR0ZXN0czplbWJlZGRlZHRlc3Rz",
        ["Content-Length"] = string.len(body),
        ["Content-Type"] = "text/xml;charset=UTF-8",
	["SOAPAction"] = "\"\""
    }

    local method
    method = string.len(body) > 0 and "POST" or "GET"

    local b, c, h, s = socket_http.request{
      url = url,
      sink = ltn12.sink.table(respBody),
      method = method,
      headers = headers,
      source = ltn12.source.string(body),
      step = ltn12.pump.step,
      proxy = nil,
    }

    if b then
        -- return the body(string), status code(number), headers(table), status line(string)
        return table.concat(respBody), c, h, s
    else
        -- return nil, and error(string)
        return b, c
    end

end

-- Initialize the webservice accessor with the URL of the backend
function initialize(backend)
  backendURL = backend
end

function getvalue(device, valuename)
end


-- send the request on the backend server (backendURL shall be initialized
function performCommand(request)
  local b, c, h, s = doHttpRequest(backendURL, request)

  if not b then
    error(c)
  end
  local ns, methode, entries = soap.decode(b)

  return entries
end


-- Perform a data writing job
function writeData(name, value)
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/asset/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:writeDataRequest><ns:assets>2254</ns:assets><ns:parameters><ns1:name>TestData</ns1:name><ns1:path>/</ns1:path><ns1:stringValue>FirstTest</ns1:stringValue></ns:parameters><ns:options sendNotification=\"true\"></ns:options></ns:writeDataRequest></soapenv:Body></soapenv:Envelope>"

  local entries = performCommand(request)
  p(entries)

  -- check if it's a valid result and extract job number
  --local result = string.find(entries,)
  return entries
end

-- Extract the table containing the job number
local function extractValue(obj)
  for _,o in ipairs(obj) do
      if type(o) == "table" and o.tag == "value" then
        return o
      end
  end
end

-- Extract the table containing the job number
local function extractDataResults(obj)
  for _,o in ipairs(obj) do
      if type(o) == "table" and o.tag == "data" then
        return extractValue(o)
      end
  end
end

local function findtagvalue(obj, key)
  for val,o in tableutils.recursivepairs(obj) do
    local root, tail = pathutils.split(val, -1)
--    print("clé: " .. val .. " valeur: "..o)
--    print("tail = "..tail)
    if tail == key then
      return o
    end
  end
end


-- Extract the table containing the job number
local function extractAssetID(obj)
  local value = findtagvalue(obj, "id")
  u.assert_not_nil(value)
  return value
end

-- Extract the table containing the job number
local function extractJobID(obj)
  for _,o in ipairs(obj) do
      if type(o) == "table" and o.tag == "job" then
        return o
      end
  end
end

-- Extract the Job status
-- If none found, return "unkown"
local function extractJobStates(JobStatesTable)
  for _,o in ipairs(JobStatesTable[1]) do
      if type(o) == "table" and o.tag then
        if o[1] == "1" then return o.tag end
      end
  end

  return "unknown"
end


------------------------------------------------------------------------
-- GLOBAL FUNCTIONS
------------------------------------------------------------------------

-- Perform a query data (embedded in the request) on the device
function queryData(request)
  local entries = performCommand(request)
  return extractDataResults(entries)
end



-- perform a request on the asset associated to the tester
-- Return the assetID
function queryAsset()
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/asset/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/asset/criteria/1.0/\" xmlns:ns2=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:queryRequest><ns:criteria><ns1:assets><ns1:simpleAsset device=\"embeddedtests1337\" externalId=\"embeddedtests1337\"/></ns1:assets></ns:criteria><ns:pagination start=\"0\" count=\"100\"/></ns:queryRequest></soapenv:Body></soapenv:Envelope>"
  local entries = performCommand(request)
  local assetID = extractAssetID(entries)
  u.assert_not_nil(assetID)

  return assetID
end


-- Call this to create a job on the server
-- Returns the job number
function createJob(request)
  local entries = performCommand(request)
  local job = extractJobID(entries)

  u.assert(job)

  return (0+job[1])
end

-- Get the status of the job identified with the provided job number
-- Returns the job status (APPLIED, DONE, CANCELLED, ETC.) and the job result (affected, waiting, success, failed, unknown)
function getJobStatus(jobNumber)
  local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:ns=\"http://www.sierrawireless.com/airvantage/schema/ws/jobs/1.0/\" xmlns:ns1=\"http://www.sierrawireless.com/airvantage/schema/api/commons/1.0/\"><soapenv:Header/><soapenv:Body><ns:queryRequest><ns:criteria><jobs><ns1:id>"
  request = request .. jobNumber
  request = request .. "</ns1:id></jobs><targetType>ASSET</targetType></ns:criteria><ns:pagination start=\"0\" count=\"1\"/><ns:select type=\"CUSTOM\"><ns1:field>state</ns1:field><ns1:field>affected</ns1:field><ns1:field>waiting</ns1:field><ns1:field>succeses</ns1:field><ns1:field>failed</ns1:field></ns:select></ns:queryRequest></soapenv:Body></soapenv:Envelope>"
  local entries = performCommand(request)

  local result = extractJobStates(entries);

  return result
end


-- Wait for the specified job status or untill timeout (in seconds).
-- list of valid status are:
--    -affected
--    -waiting
--    -successes
--    -failed
--    -unknown (should not occur)
-- Returns:
--    - status value if success
--    - nil, last known job status if timeout has been reached
function waitJobStatus(jobNumber, status, timeout)
  u.assert_not_nil(timeout)
  local starttime = os.time()
  local currenttime = os.time()
  local currentjobstatus = nil

  while (currenttime - starttime < timeout) do
    currentjobstatus = getJobStatus(jobNumber)
    if currentjobstatus == status then return status end
    sched.wait(5)
  end

  return nil, currentjobstatus
end