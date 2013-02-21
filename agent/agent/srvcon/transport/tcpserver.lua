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

require 'socket.url'
local src2string = require 'utils.ltn12.source'.tostring

local M = { }

--- Connected socket; connection is established by the peer through listensocket
M.socket = false

--- The peer connects through this socket, to set M.socket.
M.listensocket = false

--- Where incoming data are pushed to the session layer
M.sink = false

--- Pending responses, to be sent to the next http client connecting
M.responses = { }

-- Outside connection
function M.flush()
    log('SRVCON-TRANSPORT', 'DETAIL', "TCP connection received; %d message sources to serve", #M.responses)
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

function M.onaccept(skt)
    if M.socket then -- close previous connection
        M.socket :close()
    end
    M.socket = skt
    -- Monitor incoming msg and socket closing
    sched.run(M.monitor)
    -- Flush unsent messages
    for _, src in ipairs(M.responses) do M.send(src) end
    M.responses = { }
end

function M.init(url)
    local cfg = socket.url.parse(url)
    local port = tonumber(cfg.port) or M.defaultport
    local host = cfg.host or '*'
    M.listensock = socket.bind(host, port, M.onaccept)
    return 'OK'
end

-- Buffer data, it will be sent as a response to the next connection
function M.send(src)
    if M.socket then
        log('SRVCON-TRANSPORT', 'DEBUG', "Send data immediately")
        return ltn12.pump.all(src, socket.sink(M.socket))
    else
        log('SRVCON-TRANSPORT', 'DEBUG', "Buffering data, to be sent upon next connection")
        table.insert(M.responses, src)
    end
    return 'ok'
end

return M