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

function M.register(URL, type, handler)
   log("REST", "DEBUG", "Registering handler %p on URL %s for type %s", handler, URL, type)

   local closure = function (echo, env)
                       local res, err = handler(env.url:find("/") and env.url:match("/.*"):sub(2) or nil, deserialize(env.body))
                       if not res then
                           if err and type(err) == "string" then
                               log("WEB", "ERROR", "Unexpected error while executing Rest request %s [err=%d]", env.url, err)
			   end
                           return
	               end
	               echo(serialize(res))
                   end

   if not web.site[URL] then
      web.site[URL] = {
	 request_type = type,
	 mime_type = "application/json",
	 content = closure
      }
   else
      web.site[URL].contents = { ["" .. web.site[URL].request_type .. ""] = web.site[URL].content, ["" .. type .. ""] = closure }
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
