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

--------------------------------------------------------------------
-- File: TestFwk.lua
-- Description:
--  This file is the entry point for the test procedures. The main function
--  is runTests. It's automatically runned when the file is required.
--------------------------------------------------------------------
local sched    = require 'sched'
local shell    = require 'shell.telnet'
local rpc      = require 'rpc'
local os       = require 'os'
local table    = table
local RATlinux = require 'tests.managers.RATlinux'
local soapc    = require 'tests.tools.webservicesaccess'
local system   = require 'tests.tools.systemtest'
local fmt      = string.format
local copcall  = copcall
local io       = require 'io'

local logfile = nil


-- Create a shell for debug (on port 3000)
local s = {}
    s.activate = true
    s.port = 3000
    s.editmode = "edit" -- can be "line" if the trivial line by line mode is wanted
    s.historysize = 30  -- only valid for edit mode,

shell.init(s)

local client = nil
local backend
local bigresults = {}
local socketserver



--------------------------------------------------------------------
-- Results display
--------------------------------------------------------------------
local function counttests(stats)

  local nbfailedtests = stats.linuxagentcom.nbfailedtests + stats.linuxagent.nbfailedtests + stats.linuxluafwk.nbfailedtests
  local nbpassedtests = stats.linuxagentcom.nbpassedtests + stats.linuxagent.nbpassedtests + stats.linuxluafwk.nbpassedtests
  local nberrortests  = stats.linuxagentcom.nberrortests + stats.linuxagent.nberrortests + stats.linuxluafwk.nberrortests
  local total = nbfailedtests + nbpassedtests + nberrortests

  local nbtestsuites = stats.linuxagentcom.nbtestsuites + stats.linuxagent.nbtestsuites + stats.linuxluafwk.nbtestsuites
  local nbofassert = stats.linuxagentcom.nbofassert + stats.linuxagent.nbofassert + stats.linuxluafwk.nbofassert
  local nbabortedtestsuites = stats.linuxagentcom.nbabortedtestsuites + stats.linuxagent.nbabortedtestsuites + stats.linuxluafwk.nbabortedtestsuites

  return nbfailedtests, nbpassedtests, nberrortests, total, nbtestsuites, nbofassert, nbabortedtestsuites
end

local function tableconcat(source, destination)
  for i, val in ipairs(source) do
    table.insert(destination, val)
  end
end

local function concat(stats)
  local globalstats = {}

  globalstats.nbfailedtests, globalstats.nbpassedtests, globalstats.nberrortests, globalstats.totalnbtests, globalstats.nbtestsuites, globalstats.nbofassert, globalstats.nbabortedtestsuites = counttests(stats)
  globalstats.failedtests = {}
  globalstats.abortedtestsuites = {}

  tableconcat(stats.linuxagentcom.failedtests, globalstats.failedtests)
  tableconcat(stats.linuxagent.failedtests, globalstats.failedtests)
  tableconcat(stats.linuxluafwk.failedtests, globalstats.failedtests)

  tableconcat(stats.linuxagentcom.abortedtestsuites, globalstats.abortedtestsuites)
  tableconcat(stats.linuxagent.abortedtestsuites, globalstats.abortedtestsuites)
  tableconcat(stats.linuxluafwk.abortedtestsuites, globalstats.abortedtestsuites)

  return globalstats
end

local function display(value)
  print(value)
  logfile:write(value.."\n")
end

local function printstats(stats)
    local filename = "../results.txt"
    logfile = io.open(filename, "w")

    print(" ")
    display(string.rep("=", 41).." Automated Unit Test Report "..string.rep("=", 41))

    local globalresults = concat(stats)
    --local totalnbtests =  stats.nbpassedtests + stats.nbfailedtests + stats.nberrortests
    display(fmt("Run xUnit tests of %d testsuites and %d testcases (%d assert conditions) in %d seconds", globalresults.nbtestsuites, globalresults.totalnbtests, globalresults.nbofassert, stats.endtime-stats.starttime))
    display(fmt("\t%d passed, %d failed, %d errors", globalresults.nbpassedtests, globalresults.nbfailedtests, globalresults.nberrortests))
    if globalresults.nbfailedtests + globalresults.nberrortests > 0 then
        display(string.rep("-", 100))
        display("Detailed error log:")
        for i, err in ipairs(globalresults.failedtests) do
            display(fmt("%d) %s - %s.%s", i, err.type, err.testsuite, err.test))
            display(err.msg)
        end
    end
    if globalresults.nbabortedtestsuites > 0 then
        display(string.rep("-", 100))
        display(fmt("This test sequences contains %d testsuites that were aborted:", globalresults.nbabortedtestsuites))
        for _, name in ipairs(globalresults.abortedtestsuites) do display("\t"..name) end
    end
    display(string.rep("=", 100))
    print(" ")
    logfile:close()

    return globalresults
end



--------------------------------------------------------------------
-- Tests execution procedures
--------------------------------------------------------------------
-- Perform tests on Linux then write tests
local function runLinuxTests()
  RATlinux.initializeLinuxTests(soapc)
  bigresults.linuxagent = RATlinux.runLinuxAgent()
  bigresults.linuxluafwk = RATlinux.runLinuxLua()
  bigresults.linuxagentcom = RATlinux.runLinuxRemoteTests()
  --print("Tests desactives dans TestFwk ligne 109")

end

-- Perform tests on OAT target
local function runOATTests()

end

-- Perform tests on Shark target
local function runSharkTests()

end


-- Initialize the tester
-- Start servers required for all tests:
--      - Run Mediation server on local port 8888
-- Initialize results table
-- Initialize backend address
local function initializeTester()
  print "[INFO] Initializing the Tester functionnalities and Servers"

  local status, path = system.pexec("pwd")
  print("Local directory is: "..path)
  --sched.run(system.pexec, 'lua tests/tools/sockettestsvr.lua')

  --backend = "http://webplt-m2m.anyware-tech.com/ws"
  backend = "http://webplt-m2m.anyware-tech.com/portal/soap"
  soapc.initialize(backend)

  bigresults = { nbpassedtests = 0,
	      passedtests = {},
              nbfailedtests = 0,
              nberrortests  = 0,
              failedtests   = {},
              nbtestsuites  = 0,
              nbabortedtestsuites = 0,
              abortedtestsuites = {},
              starttime = os.time()}

  print "[INFO] Tester initialized"
end


-- Release the tester
-- Close
local function releaseTester()
  bigresults.endtime = os.time()
  print "[INFO] Tester released"
end


-- Test entry point
function runTests()
  initializeTester()

  -- begin to run tests on the linux target
  print "[INFO] Linux tests"
  runLinuxTests()

  -- run tests on the OAT target
  print "[INFO] OpenAT tests"
  runOATTests()

  -- run tests on the Shark target
  print "[INFO] Sharks tests"
  runSharkTests()


  releaseTester()
  print "[INFO] Tests run ended."

  local results = printstats(bigresults)

  os.exit( results.nbfailedtests + results.nberrortests + results.nbabortedtestsuites )
end

local function testsloader()
  local unittest        = require 'unittest'
  local generalfeat     = require 'tests.managers.generalfeatures'
  local commands        = require 'tests.managers.commands'
  local softupdate      = require 'tests.managers.softwareupdate'
  local ftplogstore     = require 'tests.managers.ftplogstore'
  local migrationhelper = require 'tests.managers.migrationhelper'
  local applicon        = require 'tests.managers.applicationcontainer'

end

sched.run(runTests)