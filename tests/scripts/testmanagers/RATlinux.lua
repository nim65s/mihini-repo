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

local sched = require 'sched'
local common = require 'tests.managers.RATcommon'
local rpc = require 'rpc'
sched.listen(4000)
--local system = require 'agent.system'
local system = require 'tests.tools.systemtest'

local unittest        = require 'unittest'
local generalfeat     = require 'tests.managers.generalfeatures'
local commands        = require 'tests.managers.commands'
local softupdate      = require 'tests.managers.softwareupdate'
local ftplogstore     = require 'tests.managers.ftplogstore'
local migrationhelper = require 'tests.managers.migrationhelper'
--local applicon        = require 'tests.managers.applicationcontainer'

local p = p
local print = print
local require = require
local soapc


local log = require 'log'
log.setlevel('ALL', 'LUARPC')
log.setlevel('INFO')

module(...)

-- Run embedded tests for a linux environment
--
function runLinuxAgent(shellOnly)
  print "[INFO][LINUX] Starting Linux ReadyAgent"

  -- start fake AirVantage server
  local avserver = require 'cryptotools.startserver'
  avserver.start(8888)

  if shellOnly then
    sched.run(function() system.execute("cd .. && bin/agent") end)
  else
    sched.run(function() system.execute("cd .. && pwd && xterm -bg DarkMagenta -e \"bin/agent\"") sched.signal("TESTS", "AGENT END") end )
    --sched.run(function() system.execute("../startNewAgent.sh") sched.signal("TESTS", "AGENT END") end )
  end
  --sched.run(function() system.execute("cd .. && xterm -bg DarkMagenta -e \"AGENT_DIR=$(dirname $0) && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./lib && cd $AGENT_DIR && bin/agent\"") sched.signal("TESTS", "AGENT END") end )
  --system.popen("../startNewAgent.sh")

  sched.wait(5)

  local results = common.runUnittests()
  print "[INFO][LINUX] ReadyAgent closed"

  return results
end


-- Run embedded tests for ReadyAgent lua framework
function runLinuxLua(shellOnly)
  print "[INFO][LINUX] Starting lua frameWork tests"

  --sched.run(function() system.execute("xterm -bg DarkMagenta -e \"cd .. && ./bin/lua ./lua/tests/luafwktests.lua\"") sched.signal("TESTS", "AGENT END") end )
  --
  if shellOnly then
    sched.run(function() system.execute("cd .. && ./bin/lua ./lua/tests/luafwktests.lua") end)
  else
    system.popen("xterm -bg DarkMagenta -e \"cd .. && ./bin/lua ./lua/tests/luafwktests.lua\"")
  end

  sched.wait(5)
  local results = common.runLuaFwkUnittests()
  print "[INFO][LINUX] lua frameWork tests ended"

  return results
end

function restartagent()

end

local function runLinuxTests()
  local client, err = rpc.newclient()
  local results = nil
  if (common.assert_client(client, err)) then
    client:call('require', 'tests.embeddedunittests')

    -- pre-initialize tests
    commands.init(client)
    generalfeat.init(client)
    softupdate.init(client)
    ftplogstore.init(client)
    migrationhelper.init(client)
    --applicon.init(client)

    unittest.run()
    log('RAT_LINUX', "INFO", "<close lua>")
    client:call('closeLua')
    log('RAT_LINUX', "INFO", "</close lua>")
  end

  return unittest.getStats()
end

-- Run embedded tests for ReadyAgent that requires external communication
-- with backend (jobs for example)
function runLinuxRemoteTests(shellOnly)
  print "[INFO][LINUX] Starting remote tests"

  if shellOnly then
    sched.run(function() system.execute("cd .. && bin/agent") end)
  else
    sched.run(function() system.execute("cd .. && pwd && xterm -bg DarkMagenta -e \"bin/agent\"") sched.signal("TESTS", "AGENT END") end )
  end
  --sched.run(function() system.execute("../startNewAgent.sh") sched.signal("TESTS", "AGENT END") end )
  --system.popen("../startNewAgent.sh")

  sched.wait(5)
  local results = runLinuxTests()
  print "[INFO][LINUX] remote tests ended"

  return results
end

function initializeLinuxTests(soap_client)
  soapc = soap_client
end
