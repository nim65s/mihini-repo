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

local io = require 'io'
local rpc = require 'rpc'
local log = require 'log'

local print = print
local p = p

logfilename = "defaultresults.log"

module (...)

function setlogfile(name)
  logfilename = name
end

function logresults(values)
  --[[
  fhandle = io.open(logfilename, 'a')
  fhandle:write(values)
  fhandle:flush()
  fhandle:close()
  ]]--
end

function assert_client(client, err)
  if (client == nil) then
    print ("cannot connect to client: "..err)
    return false
  else
    return true
  end
end

-- Print the result
function printResults(results)
  p(results.testsResults)
end

-- run unit tests included in the agent
function runUnittests()
  print "running unit tests"
  local client, err = rpc.newclient()
  local results = nil
  if (assert_client(client, err)) then
    client:call('require', 'tests.embeddedunittests')
    client:call('RAInitializeTests')
    client:call('RArunTests')
    local m_isFinished = client:call('RAaretestsfinished')
    while (not m_isFinished) do
      client:call('RAresumetests')
      m_isFinished = client:call('RAaretestsfinished')
    end

    results = client:call('RAgettestsResults')
    log('RAT_COMMON', "INFO", "<close lua>")
    client:call('closeLua')
    log('RAT_COMMON', "INFO", "</close lua>")
  end

  return results
end

-- run unit tests included in the agent
function runLuaFwkUnittests()
  print "running LUAFWK unit tests"
  local client, err = rpc.newclient('localhost', 7300)
--  local client, err = rpc.newclient()
  local results = nil
  if (assert_client(client, err)) then
    print "connected to lua VM"
    print "starting luaFwkTests"
    client:call('startLuaFwkTests')

    results = client:call('LuaFWKgettestsResults')
    client:call('closeLua')
  end

  return results
end