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

local at = require 'at'
local timer = require 'timer'
local mon = require 'agent.monitoring'
local tonumber = tonumber
local select = select
local sched = sched

local montable -- this variable is assigned when registering monitored variables

local function getsignal()
    local r, err = at("at+csq")
    if not r then return -1, -1 end
    local rssi, ber = (r[1]):match("+CSQ: (%d+),(%d+)")
    return tonumber(rssi), tonumber(ber)
end

local function setvalues()
    local rssi, ber = getsignal()
    montable.rssi = rssi
    montable.ber = ber
end

local t -- timer used for the polling
local function enablepolling()
    if t then return end
    t = timer.new(-10, setvalues)
end

local function setconstants()
    local r, err = at("at+cgsn")
    if r and not r[#r]:match("ERROR") then
        local imei = (r[1]):match("%d+")
        if imei then montable.imei = imei end
    end

    r, err = at("at+cimi")
    if r and not r[#r]:match("ERROR") then
        local imsi = (r[1]):match("%d+")
        if imsi then montable.imsi = imsi end
    end
end

-- there is no getvar function because at commands are causing cross boundaries Lua error
-- It will be possible to add a getvar function with Lua 5.2 since it adds "yield accross metamethod" feature
montable = mon.registerextvar("system.cellular.", enablepolling)
sched.run(setconstants)
