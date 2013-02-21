-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

--local dm = require "DeviceManagement"
local nm = require "agent.netman"
local mon = require "agent.monitoring"
local timer = require "timer"
local log = require "log"
local config = require "agent.config"
local pathutils = require "utils.path"

local table = table

--need NetworkManager/Bearer properly configured
assert(config.network.bearer)

local stats = {}
local retries = {}
local hookber,hooknm

local polled_vars= {}

--only update watched vars
local function updatevars(bname)
    local mvars = mon.vars.system.netman

    if polled_vars[bname] == "all" then
        for k,v in pairs(nm.bearers[bname].infos) do mvars[bname][k] = v end
    else
        for k, _ in pairs(polled_vars[bname]) do mvars[bname][k] = nm.bearers[bname].infos[k] end
    end
end

--hook for signal emitter "NETMAN-BEARER"
local function bearerHook(ev, ber)
    local nmbearers = nm.bearers
    if not nmbearers[ber.name] or nmbearers[ber.name] ~=  ber then
        log("Monitoring-netman", "WARNING", "Bearer EVENT from unregistered bearer")
    end
    -- update stats.BEARERNAME_lastmount_date
    local bstat = ber.infos
    if ev == "MOUNTED"  then
        bstat['mountdate'] = os.time()
        bstat['mountretries'] = retries[ber.name];
        retries[ber.name] = 0;
    elseif ev == "MOUNT_FAILED" then
        retries[ber.name] = retries[ber.name]+1
    end

    -- force	update Stats for this bearer
    updatevars(ber.name)
end

--hook for signal emitter "NETMAN"
local function bearernetman(ev, ber)
    -- update default bearer
    if polled_vars["netman"]["defaultbearer"] or polled_vars["netman"]["*"]  then
        mon.vars.system.netman.defaultbearer =  nm.defaultbearer and nm.defaultbearer.name
    end
end

local function setdynvalues()
    local mvars = mon.vars.system.netman
    for ber, _ in pairs(config.network.bearer) do
        if polled_vars[ber]["*"] or polled_vars[ber].RX or polled_vars[ber].TX then
            mvars[ber].RX = nm.bearers[ber].infos.RX
            mvars[ber].TX = nm.bearers[ber].infos.TX
        end
    end
end

local t -- timer used for the polling
local function enablepolling(path, varname)
    --bname is the last but one part of the path
    local pathsegs = pathutils.segments(path)
    bname = pathsegs and pathsegs[#pathsegs-1]
    if not varname then
        --group registeration
        polled_vars[bname] = "all"
        -- RX / TX for existing bearer
        if not t and (config.network.bearer[bname]) then
            t = timer.new(-20, setdynvalues)
        end
    else
        if polled_vars[bname]~="all" then polled_vars[bname][varname] = true end
        if not t and (varname == "RX" or varname =="TX") then
            t = timer.new(-20, setdynvalues)
        end
    end
end

--init retries stuff

for k,v in pairs(config.network.bearer) do
    polled_vars[k]={}
    retries[k] = 0
end
--level 0 vars
polled_vars["netman"]={}

hookber = sched.sighook("NETMAN-BEARER", "*", bearerHook)
hooknm = sched.sighook("NETMAN", "*", bearernetman)

--register level 0 var(s)
mon.registerextvar("system.netman.defaultbearer",  enablepolling, function () return nm.defaultbearer and nm.defaultbearer.name end)

--register level 1 groups (by bearer name)
for bname,_ in pairs(config.network.bearer) do
    local function getvars(path, varname)
        return nm.bearers[bname] and nm.bearers[bname].infos[varname]
    end

    local function listvars(path)
        local res= {}
        if nm.bearers[bname] then
            for k,v in pairs(nm.bearers[bname].infos) do table.insert(res, k) end
        end
        return res
    end
    mon.registerextvar("system.netman."..bname..".", enablepolling, getvars, listvars)
end
