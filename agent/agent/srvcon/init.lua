-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Gilles Cannenterre for Sierra Wireless - initial API and implementation
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local require     = require
local sched       = require "sched"
local log         = require "log"
local config      = require "agent.config"
local asscon      = require "agent.asscon"
local usource     = require "utils.ltn12.source"
local upath       = require "utils.path"
local timer       = require "timer"
local lock        = require "lock"
local ltn12       = require "ltn12"
local checks      = require "checks"
require 'coxpcall'
require 'socket.url'

global 'getdeviceid'

local M = { }

global 'agent'; agent.srvcon = M

local awtda_deserialize = require "bysant.awtda".deserializer()


-- hook that is set to nil by default: if non nil this function is called prior to doing the connexion
M.preconnecthook = false 

-- will be filled with a `require 'agent.srvcon.transport.XXX'` where XXX is 
-- a session management protocol. Currently, `security` and `default` are 
-- supported. This is set during the `srvcon` module's initialization, based on
-- the agent's config.
M.session = nil

-- Dispatch deserialized server messages to the appropriate assets through EMP.
local function dispatch_message(envelope_payload)

    if not envelope_payload or #envelope_payload <= 0 then return 'ok' end
    
    --base.global 'last_payload'
    --base.last_payload = payload
    local offset = 1
    while offset <= #envelope_payload do
        local msg
        msg, offset = awtda_deserialize(envelope_payload, offset)
        if msg==nil and tonumber(offset) or msg=='' then
            log('SRVCON', 'DETAIL', 'Empty message from server')
        elseif msg.__class == 'Message' then
            local name = upath.split(msg.path, 1)
            local r, errmsg = asscon.sendcmd(name, "SendData", msg)
            if not r then
                -- TODO: build and send a NAK to the server through a session+transport
                log("SRVCON", "ERROR", "Failed to dispatch server message %s"..sprint(msg))
            end
         elseif msg.__class == 'Response' then
            log('SRVCON', 'WARNING', "Received a response %d: %s to ticket %d",
                msg.status, sprint(msg.data), msg.ticketid)
            log('SRVCON', 'WARNING', "No special handling of responses implemented")
         else
            log('SRVCON', 'ERROR', "Received unsupported envelope content: %s",
                sprint(msg))
        end
    end
end 

M.sourcefactories = { }

M.pendingcallbacks = { }

local function concat_factories(factories)
    return function()
        local sources = { }
        for k, _ in pairs(factories) do
            table.insert(sources, k())
        end
        return ltn12.source.cat(unpack(sources))
    end
end

local function restore_factories(factories)
    for f, _ in pairs(factories) do
        M.sourcefactories[f]=true
    end
end

function M.dosession()
    local pending_factories
    M.sourcefactories, pending_factories = { }, M.sourcefactories
    local source_factory = concat_factories(pending_factories)
    local r, errmsg = M.session.send (source_factory)
    if not r then 
        log('SRVCON', 'ERROR', "Error while sending data to server: %s", errmsg)
        restore_factories(pending_factories);
        return nil, errmsg 
    end
    for callback, _ in pairs(M.pendingcallbacks) do
        callback(r, errmsg)
    end
    return "ok"
end

-- TODO: document what this does.
function M.parseonewaypackage(message)
    error "SMS support disabled"
    local payload = {}
    session.parseonewaypackage(ltn12.source.string(message), ltn12.sink.table(payload))
    return  dispatch_message(table.concat(payload))
end

--- Give data to the server connector and force it to be flushed to server.
--
--  @param factory an optional function, returning an ltn12 data source. The factory might be called
--    more than once, in case of failure or authentication issue.
--  @param callback an optional user function to be called when the data has been sent to the server.
--
function M.pushtoserver(factory, callback)
    checks('?function', '?function')
    lock.lock(M)
    if factory  then M.sourcefactories[factory] = true end
    if callback then M.pendingcallbacks[callback] = true end
    lock.unlock(M)
end

--- Force data fed through @{#pushtoserver} to be actually flushed to the server.
--
--  @param factory an optional function, returning an ltn12 data source. The factory might be called
--    more than once, in case of failure or authentication issue.
--  @param callback an optional user function to be called when the data has been sent to the server.
--  @param latency an optional delay after which connection to the server is forced.
--
function M.connect(latency)
    checks('?number')
    if latency and latency<0 then return nil, "latency must be positive integer" end
    return timer.latencyexec(M.dosession, latency) 
end

--- Responds to request to connect to server sent through EMP messages.
local function EMPConnectToServer(assetid, latency)
    local s, err = M.connect(latency)
    if not s then return 513, err else return 0 end
end

--- Sets up the module according to agent.config settings.
function M.init()

    -- EMP callbacks
    asscon.registercmd("ConnectToServer", EMPConnectToServer)

    -- Apply agent.config's settings
    if type(config.server.autoconnect) == "table" then
        log("SRVCON", "DETAIL", "Setting up connection policy")
        for policy, p in pairs(config.server.autoconnect) do
            if policy == "period" then
                if tonumber(p) then 
                    timer.new(tonumber(p)*(-60), connect, 0)
                else
                    log("SRVCON", "ERROR", "Ignoring unknown period: '%s'", tostring(p))
                end
            elseif policy == "cron" then
                timer.new(p, connect, 0)
            elseif policy == "onboot" then
                M.connect(tonumber(p) or 30)
            else
                log("SRVCON", "ERROR", "Ignoring unknown policy: '%s'", tostring(policy))
            end
        end
    end

    -- Make sure a device ID will be set before the agent starts.
    local function setdevid()
        if (not config.agent.deviceId or config.agent.deviceId == "") then
            global 'getdeviceid'
            if getdeviceid and type(getdeviceid) == "function" then
                config.agent.deviceId =  getdeviceid()
            else
                log("SRVCON", "ERROR", "No deviceId defined in config and no global function getdeviceid defined");
            end
        end
    end
    sched.sigrunonce("ReadyAgent","InitDone", setdevid)

    -- Choose and load the appropriate session and transport modules, depending on config.
    local cs, session_name = config.server, 'default'
    local transport_name = socket.url.parse(cs.url).scheme :lower()
    
    local transport = require ('agent.srvcon.transport.'..transport_name)
    if not transport then return nil, "cannot get transport" end

    if cs.authentication or cs.encryption then session_name = 'security' end
    M.session   = require ('agent.srvcon.session.'..session_name)
    if not M.session then return nil, "cannot get session manager" end

    local r, errmsg = transport.init(cs.url);
    if not r then return r, errmsg end
    r, errmsg = M.session.init{
        transport      = transport,
        msghandler     = dispatch_message,
        deviceid       = config.agent.deviceId,
        authentication = cs.authentication,
        encryption     = cs.encryption
    }
    if not r then return r, errmsg end
    return "ok"
end

return M
