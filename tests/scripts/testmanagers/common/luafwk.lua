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

local unittest = require "unittest"
local t = unittest.newtestsuite("luafwk")
local assert = unittest.assert
local rpcclient

function t.init(client)
  t.rpcclient = client
end

-- This script will tests the commands part

function t:setup()
  local path = "xterm -bg DarkMagenta -e \"cd .. && ./bin/lua ./lua/tests/luafwktests.lua\""
  local target = "Linux"
  local host = 'localhost'
  local port = nil

end

function t:teardown()
end

local function insertStats()
end

local function runtestsuite(name)
  assert_not_nil(name)
  assert(t.rpcclient:call('require', 'tests.'..name), "Can't load"..name)
  t.rpcclient:call('unittest.run')
  local stats = t.rpcclient:call('unittest.getStats')
  assert(stats, "Can't get stats from unittest execution")

  local fct_script=[[
      local loader = require"utils.loader"
      loader.unload('tests.']]..name..[[)
      loader.unload('unittest')
      ]]
  local fct_tmp = t.rpcclient:newexec(fct_script)
  assert(fct_tmp, "Can't create remote function to unload code")
  fct_tmp()

end

function t:test_executeRPC()
  runtestsuite('rpc')
end

function t:test_executePersist()
  runtestsuite('persist')
end

function t:test_executeLuatobin()
  runtestsuite('tests.luatobin')
end

function t:test_executeQdbm()
  runtestsuite('tests.qdbm')
end

function t:test_executeSched()
  runtestsuite('tests.sched')
end

function t:test_executeSocket()
  runtestsuite('tests.socket')
end

function t:test_executeCrypto()
  runtestsuite('tests.crypto')
end


return t