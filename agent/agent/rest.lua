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
                       local suburl = env.url:find("/") and env.url:match("/.*"):sub(2) or nil
                       local environment = { ["suburl"] = suburl, ["params"] = env.params, ["payload"] = payload}
                       local res, err = handler(environment)
                       if not res and type(err) == "string" then
                           log("REST", "ERROR", "Unexpected error while executing rest request %s: %s", env.url, err)
                           return res, err
                       end
	               echo(serialize(res))
		       return "ok"
                   end
     if not web.pattern[URL] then
        web.pattern[URL] = { }
     end
     web.pattern[URL]["".. rtype ..""] = { ["content"] = closure, ["sink"] = (rtype == "POST" or rtype == "PUT") and payload_sink or nil }
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
