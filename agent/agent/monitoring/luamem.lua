-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Cuero Bugot for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local timer = require 'timer'
local mon = require 'agent.monitoring'

local montable -- this variable is assigned when registering monitored variables

local function getvalue()
    collectgarbage("collect")
    return collectgarbage("count")
end

local function setvalues()
    montable.luaramusage = getvalue()
end

local t -- timer used for the polling
local function enablepolling()
    if t then return end
    t = timer.new(-10, setvalues)
end

montable = mon.registerextvar("system.luaramusage", enablepolling, getvalue)
