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
local u          = require 'unittest'
local os         = require 'os'
local log        = require 'log'

local config     = require 'tests.config'
local mediation  = require 'tests.mediation'
--local monitoring = require 'tests.monitoring' -- currently disabled
local hessian    = require 'tests.hessian'
local stagedb    = require 'tests.stagedb'
local treemgr    = require 'tests.treemgr'
local bysant     = require 'tests.bysant'
local airvantage     = require 'tests.airvantage'
local racon          = require 'tests.raconunittests'
local asset_tree = require 'tests.asset_tree'
local update = require "tests.update"

local ended = false

function storelog()
end

function definefilter()
end

function RAInitializeTests()
  print "unittests initialized"
end

function RArunTests()
  u.run()
  ended = true
end

function RAaretestsfinished()
  return ended
end

function RAgettestsResults()
  return u.getStats()
end

function RAresume()

end

function closeLua()
  log('unittests', 'INFO', "Killing slave process")
  os.exit(0)
end

function RASpecificCommand()
  local system = require "lfs"
  return lfs.currentdir()
end

function checklog(filter, delay)
  local logmanager = logm.new()
  logmanager:checklog(filter, delay)
end