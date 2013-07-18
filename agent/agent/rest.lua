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
require 'web.auth.digest'
local config = require 'agent.config'
local yajl = require 'yajl'

local M = {}
local initialiazed = false

local serialize = yajl.to_string

local function deserialize(str)
   if not str then
      return yajl.null
   end
   local status, result = pcall(yajl.to_value, '['..str..']')
   return status and result[1] or nil, "Invalid JSON input: " .. str
end

function M.register(URL, rtype, handler, payload_sink)
   log("REST", "DEBUG", "Registering handler %p on URL %s for type %s", handler, URL, rtype)

   local closure = function (echo, env)
                       local payload, res, err
                       if not payload_sink then
                          payload, err = deserialize(env.body)
                          if not payload and err then return nil, err end
                       end
                       local suburl = env.url:find("/") and env.url:match("/.*"):sub(2) or nil
                       local environment = { ["suburl"] = suburl, ["params"] = env.params, ["payload"] = payload}
                       res, err = handler(environment)
                       if not res and type(err) == "string" then
                           log("REST", "ERROR", "Unexpected error while executing rest request %s: %s", env.url, err)
                           return res, err
                       end
	               echo(res ~= "ok" and serialize(res) or nil)
		       return "ok"
                   end
     if not web.pattern[URL] then
        web.pattern[URL] = { }
     end
     local authentication = nil
     if config.rest.restricted_uri and config.rest.restricted_uri[URL] then
           authentication = true
     elseif config.rest.restricted_uri and config.rest.restricted_uri["*"] then
           authentication = true
     end
     web.pattern[URL]["".. rtype ..""] = {
                ["content"] = closure,
                ["header"] = authentication and web.authenticate_header(config.rest.authentication.realm, config.rest.authentication.ha1) or nil,
                ["sink"] = (rtype == "POST" or rtype == "PUT") and payload_sink or nil
     }
   return "ok"
end

function M.unregister(URL, rtype, handler)
   log("REST", "DEBUG", "Unregistering handler %p on URL %s for type %s", handler, URL, rtype)

   if not web.pattern[URL] then
      return nil, "resource does not exist"
   end
   web.pattern[URL][rtype] = nil
   local i = 0
   for k, v in web.pattern[URL] do  i = i + 1 end
   if i == 0 then
      web.pattern[URL]  = nil
   end
end

function M.init()
   if initialiazed == true then
      return nil, "already initialiazed"
   end
   web.start(config.rest.port and config.rest.port or 8357)
   initialiazed = true
   return "ok"
end

return M
