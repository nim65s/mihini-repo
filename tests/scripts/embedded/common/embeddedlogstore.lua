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

local log = require "log"
local logstore = require "log.store"
local Config = require "agent.config"

function testlog_setup()
    Config.set("log.policy", {})
    Config.set("log.policy.name", "context")
    Config.set("log.policy.params",{})
    Config.set("log.policy.params.level", "WARNING")
    Config.set("log.policy.params.ramlogger", {size = 2048})
    Config.set("log.policy.params.flashlogger", {size = 15*1024, path="logs/" })
end

local function findString(str)
  local source = logstore.logflashgetsource()


end

function setlogpolicy(logpolicy)
  Config.set("log.policy.name", logpolicy)

  -- empty the flash log
end

function emptyLogs()
  local source = logstore.logflashgetsource()
  local snk, t = ltn12.sink.table()
  ltn12.pump.all(ltn12.source.chain(source), snk)
end


-- Initialize the ReadyAgent in order to test the "context" policy
function testlog_context()
  -- generate logs on the device
  log("TESTS", "INFO", "log1")
  log("TESTS", "INFO", "log2")
  log("TESTS", "WARNING", "log3")
  log("TESTS", "INFO", "log4")

  -- check that only the logs log1, log2, log3 are stored in flash
end

-- Initialize the ReadyAgent in order to test the "sole" policy
function testlog_sole()
  -- generate logs on the device
  log("TESTS", "INFO", "log1")
  log("TESTS", "INFO", "log2")
  log("TESTS", "WARNING", "log3")
  log("TESTS", "INFO", "log4")

  -- check that only the log3 value is stored in flash
end

-- Initialize the ReadyAgent in order to test the "sole" policy
function testlog_bufferedall()
  --emptyLogs()

  -- generate logs on the device
  log("TESTS", "INFO", "log1")
  log("TESTS", "INFO", "log2")
  log("TESTS", "WARNING", "log3")
  log("TESTS", "INFO", "log4")

  -- check that all the logs are stored in RAM and nothing in flash
  --local source = logstore.logflashgetsource()

end

-- Initialize the ReadyAgent in order to test the case of huge logs quantity
function testlog_biglogs()
    -- generate logs on the device
    local cnt = 0
    while (cnt < 1000) do
        log("TESTS", "INFO", "Testing huge logs #"..cnt)
	cnt = cnt + 1
    end
end

function testlog_teardown()
    Config.set("log.policy", nil)
end