-------------------------------------------------------------------------------
-- Copyright (c) 2013 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Romain Perier for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

require 'web.server'
local config = require 'agent.config'
local yajl = require 'yajl'

local M = {}
local initialiazed = false

local serialize = yajl.to_string

local function deserialize(str)
   return str and yajl.to_value('['..str..']')[1] or yajl.null
end

function M.register(URL, rtype, handler, payload_sink)
   log("REST", "DEBUG", "Registering handler %p on URL %s for type %s", handler, URL, rtype)

   local closure = function (echo, env)
                       local payload = payload_sink and nil or deserialize(env.body)
                       local res, err = handler(env.url:find("/") and env.url:match("/.*"):sub(2) or nil, payload)
                       if not res and type(err) == "string" then
                           log("REST", "ERROR", "Unexpected error while executing rest request %s: %s", env.url, err)
                           return res, err
                       end
	               echo(serialize(res))
		       return "ok"
                   end

   if not web.site[URL] then
      web.site[URL] = {
	 request_type = rtype,
	 content = closure,
	 sink = (rtype == "POST" or rtype == "PUT") and payload_sink or nil
      }
   else
      web.site[URL].contents = { ["" .. web.site[URL].request_type .. ""] = web.site[URL].content, ["" .. rtype .. ""] = closure }
      web.site[URL].content = nil
      web.site[URL].request_type = nil
   end
   return "ok"
end


function M.init()
   if initialiazed == true then
      return nil, "already initialiazed"
   end
   web.start(config.rest.port and config.rest.port or 8080)
   initialiazed = true
   return "ok"
end

return M
