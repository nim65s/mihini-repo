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
local http = require "socket.http"
local ltn12 = require "ltn12"

local table = table
local string = string
local type = type

local M = setmetatable({ }, { __type='srvcon.transport' })

M.sink = false
M.url  = false
M.proxy = nil -- TODO: provision it without creating an agent.config dependency

function M.init(url)
    checks('string')
    M.url = url
    return 'ok'
end

function M.send(src)
    log("SRVCON-TRANSPORT", "DETAIL", "http request %q...", M.url)
    local headers = { }
    headers["Content-Type"] = "application/octet-stream"
    headers["Transfer-Encoding"] = "chunked"

    local body, code, headers, statusline = http.request {
      url     = M.url,
      sink    = assert(M.sink, 'Unconfigured session sink in transport module'),
      method  = "POST",
      headers = headers,
      source  = src,
      proxy   = M.proxy,
    }

    log("SRVCON-TRANSPORT", "DETAIL", "http response status: %s", tostring(code))

    if not body then return nil, code
    elseif (type(code) == "number" and (code < 200 or code >= 300)) then
		return nil, code
	else
        return code
    end
end

return M