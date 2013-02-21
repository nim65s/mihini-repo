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

local log = require "log"
local ltn12 = require "ltn12"
local awtda = require 'bysant.awtda'
local awtda_deserialize = awtda.deserializer()

-- 

local M = setmetatable({ }, { __type='srvcon.session' })

-- sessions are numbered, this counter keeps track of attributed numbers.
M.last_session_id = 0

--- Envelopes retrieved from the server through the transport layer are
--  pushed in this queue
M.incoming = require 'pipe' ()

-- sink state
local pending_data = ''
local partial = nil

--- Receives transport data as a byte sink, stacks envelope payloads
--  in the `M.incoming` pipe as they are completed.
function M.sink(data)
    if not data then return 'ok' end
    pending_data = pending_data .. data
    local envelope, offset 
    envelope, offset, partial = awtda_deserialize (pending_data, partial)
    if offset=='partial' then return 'ok'
    elseif envelope then
        M.incoming :send (envelope.payload)
        pending_data = pending_data :sub (offset, -1)
        return 'ok'
    else
        awtda_deserialize :reset()
        return nil, offset -- actually an error msg
    end
end

--- Wraps a source into an AWTDA envelope and sends it through the session's
--  transport layer
-- @param src_factory a source factory, i.e. a function returning an ltn12 source
--   function. With the default session, the factory will only be called once,
--   but some more complex session managers might call it more than once,
--   e.g. because a message must be reemitted for security reasons.
-- @return `"ok"` or `nil` + error message
function M.send(src_factory)
    M.last_session_id = M.last_session_id + 1
    log("SRVCON-SESSION", "DETAIL", "Opening session #%d", M.last_session_id)
    local r, env_wrapper, errmsg
    env_wrapper, errmsg = assert(awtda.envelope { id = M.deviceid })
    local source = ltn12.source.chain(src_factory(), env_wrapper)
    r, errmsg = M.transport.send (source)
    if not r then return r, errmsg end
    log("SRVCON-SESSION", "DETAIL", "Closing session #%d with status %s.", M.last_session_id, tostring(r))
    return r
end

--- Report server messages to the handler provided by srvcon at module init time.
function M.monitor(handler)
    while true do
        local msg = M.incoming :receive() -- TODO: handle timeouts ?
        handler(msg)
    end
end

M.init_keys = { 'transport', 'msghandler', 'deviceid' }

function M.init(cfg)
    for _, key in ipairs(M.init_keys) do
        local val = cfg[key]
        if not val then return nil, 'missing config key '..key end
        M[key]=val
    end
    sched.run(M.monitor, cfg.msghandler)
    M.transport.sink = M.sink
    return 'ok'
end

return M