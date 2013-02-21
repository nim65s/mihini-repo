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
require 'web.server'
require 'socket.url'
local src2string = require 'utils.ltn12.source'.tostring

local M = { }

--- If a table it put here, it will accumulate the history of data exchanges
--  under the form of triplet { timestamp, direction, serialized_message }
--  with direction a boolean: true for outgoing message, false for incoming ones.
M.history = false

--- Where incoming data are pushed to the session layer
M.sink = false

--- Pending responses, to be sent to the next http client connecting
M.responses = { }

-- Outside connection
function M.page(echo, env)
    log('SRVCON-TRANSPORT', 'DETAIL', "HTTP request receives; %d message sources to serve", #M.responses)
    for _, src in ipairs(M.responses) do
        local str = src2string(src)
        printf ('Serving %d bytes of response: %q', #str, str)
        if M.history then table.insert(M.history, str) end
        echo(str)
    end
    M.responses = { }
end


function M.init(url)
    local cfg = socket.url.parse(url)
    local path = cfg.path :gsub ('^/', '') or cfg.path
    web.site[path] = M.page 
    print ("adding page at "..path)
    return 'OK'
end

-- Buffer data, it will be sent as a response to the next connection
function M.send(src)
    log('SRVCON-TRANSPORT', 'DEBUG', "Buffering data, to be sent upon next connection")
    table.insert(M.responses, src)
    return 'ok'
end

return M