-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
--     Cuero Bugot        for Sierra Wireless - initial API and implementation
--     Gilles Cannenterre for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local require = require
local sched = require "sched"
local bearer = require "agent.bearer"
local config = require "agent.config"
local log = require "log"
local lock = require "lock"
local timer = require "timer"
local system = require "agent.system"
local socket = require "socket"
local pairs = pairs
local ipairs = ipairs
local unpack = unpack
local tonumber = tonumber
local tostring = tostring
local type = type
local base = _G

module(...)

bearers = {}
defaultbearer = nil
local failure_count

-- mount the bearer given as parameter
local function mount(bearer)
    --log("NETMAN", "INFO", "Trying to mount %s", bearer.name)
    if not bearer then return end
    lock.lock(bearer)
    local mount, err = bearer:mount()
    local bconfig = config.network.bearer[bearer.name]
    local retry = bconfig and tonumber(bconfig.retry or config.network.retry) or 1
    local period = bconfig and  tonumber(bconfig.retryperiod or config.network.retryperiod) or 1
    -- while not connected, retry
    while not mount and retry > 0 do
        log("NETMAN", "WARNING", "%s, %q retrying(%d)", err, bearer.name, retry)
        retry = retry - 1
        sched.wait(period)
        mount, err = bearer:mount()
    end
    if mount then
        log("NETMAN", "INFO", "%q mounted", bearer.name)
    else
        log("NETMAN", "ERROR", "Cannot mount %q", bearer.name)
    end
    lock.unlock(bearer)
    return mount, err
end

-- register bearer gateway as default route
local function register(bearer, regto, check_route)
    if not bearer then return end
    lock.lock(bearer)
    local ok, err = bearer:setdefault()
    if not ok then
        log("NETMAN", "ERROR", "Cannot select %q, %s", bearer.name, err)
        lock.unlock(bearer)
        sched.signal("NETMAN", "DISCONNECTED")
        return nil, err
    end
    if check_route then
        ok, err = tcpping()
        if not ok then
            -- route is set to bearer but tcpping failed (maybe a dns issue)
            log("NETMAN", "ERROR", "Cannot select %q, %s", bearer.name, err)
            bearer:unmount()
            lock.unlock(bearer)
            sched.signal("NETMAN", "DISCONNECTED")
            return nil, err
        end
    end
    defaultbearer = bearer
    local bconfig = config.network.bearer[bearer.name]
    local connectto = tonumber(bconfig.maxconnectiontime or config.network.maxconnectiontime) or 0
    if bearer.tmaxconnect then timer.cancel(bearer.tmaxconnect) bearer.tmaxconnect = nil end
    if regto and connectto > 0 then
        bearer.tmaxconnect = timer.new(connectto, connect)
        log("NETMAN", "INFO", "Selected, default route through %q for %ds", bearer.name, connectto)
    else
        log("NETMAN", "INFO", "Selected, default route through %q", bearer.name)
    end
    lock.unlock(bearer)
    sched.signal("NETMAN", "CONNECTED", bearer.name)
    return "ok"
end

-- select bearer
local function select(bearername, check_route)
    --log("NETMAN", "INFO", "Selecting %q", bearername or "...")
    local ok, err
    -- bearername is set, bearer gateway is defaultroute
    if bearername then
        local b = bearers[bearername]
        if b then
            if not b.connected then ok, err = mount(b) end
            if b.connected then
                ok, err =  register(b, false, check_route)
                if ok then return ok end
            end
        end
    else
        -- bearername is not set, look for a default gateway in priority list
        if config.network.bearerpriority then
            for i,v in ipairs(config.network.bearerpriority) do
                local b = bearers[v]
                if b then
                    if not b.connected then ok, err = mount(b) end
                    if b.connected then
                        ok, err =  register(b, i > 1, check_route)
                        if ok then failure_count = tonumber(config.network.maxfailure) return ok end
                    end
                else
                    log("NETMAN", "WARNING", "Cannot select unknown bearer %q", tostring(v) or "?")
                end
            end
            if failure_count then
                failure_count = failure_count - 1
                if failure_count <= 0 then
                    err = "no retries left: rebooting"
                    -- message will be displayed by the next call to log
                    system.reboot()
                end
            end
        end
    end
    -- failed on all counts
    err = err or "No elligible bearer"
    log("NETMAN", "ERROR", "Cannot select, %s", err)
    return nil, err
end

------------------------------------------------------------------------------
-- 'Ping' by trying to open a tcp socket on config.network.pinghost                                             --
------------------------------------------------------------------------------
function tcpping(host, port)
    local s, err = socket.connect(host or config.network.pinghost or "www.google.com", port or config.network.pingport or 80)
    return (s and true or nil), err
end

------------------------------------------------------------------------------
-- Try to set default route                                                 --
--    bearername :    set as default route this bearer (mount if necessary) --
--    check_route:    perform a verify to validate the default route        --
------------------------------------------------------------------------------
function connect(bearername, check_route)
    lock.lock(_M)
    local ok, err = select(bearername, check_route)
    lock.unlock(_M)
    return ok, err
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- tryaction(action, ...) returns action(...) results when the network is working and nil followed by an error on network error
--      More precisely it returns the results of the function action() if its first result is non nil, otherwise try to verify/remount the network
--      connection:
--              If the network connection was not successfully remounted, just return the connection error.
--              If the network connection is remounted and working, return the result of a new action(...) call.
--      Note:   tryaction function uses the current bearer or select the best (if current is not available)
--              action must be a function that return non nil when it succeeded and nil followed by an error when it failed.
--              look at the code if your are still in doubt...
------------------------------------------------------------------------------------------------------------------------------------------------------
base.tryaction = function (action, ...)
    log("NETMAN", "DETAIL", "Trying to connect...")
    local s, err
    local r = { action(...) }
    if not r[1] then
        log("NETMAN", "WARNING", "Try action: action error, %q", r[2] or "unknown")
        lock.lock(_M)
        if defaultbearer then
            s, err = tcpping()
            if s then
                -- the network was actually working but the action failed, no need to try again.
                -- Just return the error of the previous call to action.
                lock.unlock(_M)
                return unpack(r)
            else
                -- Otherwise, unmount the bearer to remount it and retry !
                log("NETMAN", "WARNING", "TCP ping error, %q", err or "unknown")
                defaultbearer:unmount()
            end
        end

        -- Select the default bearer
        s, err = select(nil, true)
        if not s then
            lock.unlock(_M)
            return s, err
        end
        
        lock.unlock(_M)
        return action(...)
    end
    return unpack(r)
end

-- automount bearer
local function automount(bearer, sel)
    bearer.automounting = true
    log("NETMAN", "DETAIL", "automounting %q", bearer.name)
    if bearer.tmount then timer.cancel(bearer.tmount) bearer.tmount = nil end
    local ok, err = mount(bearer)
    if ok then
        if sel and defaultbearer and defaultbearer.connected then register(defaultbearer, defaultbearer.tmaxconnect, false) end
        bearer.automounting = false
    else
        local bconfig = config.network.bearer[bearer.name]
        local delay = bconfig and (((tonumber(bconfig.retry or config.network.retry) or 1) + 1) * ((tonumber(bconfig.open_timeout) or 10) + (tonumber(bconfig.retryperiod or config.network.retryperiod) or 10)))
        bearer.tmount = timer.new(tonumber(bearer.automount) or delay, automount, bearer)
        log("NETMAN", "DETAIL", "automounting %q failed, retrying in %ds", bearer.name, bearer.tmount and tonumber(bearer.tmount.delay))
    end
    return ok, err
end

-- hook on MOUNTED / UNMOUNTED
local function bearereventhook(ev, b)
    if type(b) == "table" and b == bearers[b.name] then
        if not b.connected and b.automount and not b.automounting then automount(b, true) end
    end
end

-- hook on ra init
local function rahook()
    lock.lock(_M)
    failure_count = tonumber(config.network.maxfailure)
    sched.sigrun("NETMAN-BEARER", "*", bearereventhook)
    for k,v in pairs(config.network.bearer) do
        local b, err = bearer.new(k, v.automount)
        if b then
            bearers[k] = b
            if not b.connected and b.automount and not b.automounting then automount(b, false) end
        else
            log("NETMAN", "ERROR", "%q, %s", tostring(k) or "?", err or "Cannot be initialized")
        end
    end
    select()
    lock.unlock(_M)
end

-------------------------
-- initialize module   --
-------------------------
function init()
    if not config.network.bearer then return nil, "No bearer in config" end
    sched.sigrunonce("ReadyAgent", "InitDone", rahook)
    return "ok"
end
