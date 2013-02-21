-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local socket = require 'socket'
require 'socket.url'

local M = setmetatable({ }, { __type='srvcon.transport' })

M.port        = false
M.servername  = false
M.socket      = false
M.sink        = false
M.defaultport = 2100

--- Create or recreate the TCP connection to the server.
function M.getsocket()
    if M.socket then return M.socket end
    local errmsg
    M.socket, errmsg = socket.connect(M.servername, M.port)
    if M.socket then sched.run(M.monitor) end
    return M.socket, errmsg
end

--- Reading loop: monitor an open TCP socket for incoming data, and cleans up
--  when it's shut down remotely.
-- Automatically attached to the socket, when it's created, for its lifetime.
function M.monitor()
    assert(M.sink, "missing session sink in transport layer")
    repeat
        local data, err = M.socket :receive '*'
        if data then M.sink(data) end
    until not data
    M.socket :close()
    M.socket = false
end

--- Sends the payload of an ltn12 source to the server.
function M.send(src)
    local skt, errmsg = M.getsocket()
    if not skt then return nil, errmsg end
    return ltn12.pump.all(src, socket.sink(skt))
end

function M.init(url)
    checks('string')
    local cfg = socket.url.parse(url)
    if cfg.scheme ~= 'tcp' then
        log('SRVCON-TRANSPORT', 'ERROR',
            "Transport scheme changed from tcp to %q", tostring(cfg.scheme))
        return nil, "invalid config"
    else
        M.servername, M.port = cfg.host, tonumber(cfg.port) or M.defaultport
    end
    return 'ok'
end

return M