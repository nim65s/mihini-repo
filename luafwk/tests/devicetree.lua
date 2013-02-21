-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Romain Perier for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local devicetree = require 'racon.devicetree'
local u = require 'unittest'
local t = u.newtestsuite("devicetree")

local variableHasChanged = 0
local regId = nil

local function notifyVariablesCb()
   variableHasChanged = 1
end

function t :setup()
   assert(devicetree.init())
end

function t :teardown()
   assert(variableHasChanged == 1)
end

function t :test_dt_Register()
   local id, err

   while true do
      id, err = devicetree.register({ "config.toto", "config.tata" }, notifyVariablesCb)
      if id and not err then break end
      if not id and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end
   regId = id
end

function t :test_dt_SetAndGet()

   while true do
      local status, err = devicetree.set("config.toto", "toto")
      if status and not err then break end
      if not status and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end

   while true do
      local status, err = devicetree.set("config.tata", "tataw")
      if status and not err then break end
      if not status and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end

   while true do
      local status, err = devicetree.set("config.tata", "tata")
      if status and not err then break end
      if not status and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end

   local value, err
   while true do
      value, err = devicetree.get("config.toto")
      if value and not err then break end
      if not value and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end
   assert(type(value) == "string" and value == "toto")

   while true do
      value, err = devicetree.get("config.tata")
      if value and not err then break end
      if not value and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end
   assert(type(value) == "string" and value == "tata")

   while true do
      value, err = devicetree.get("config")
      if not value and err then break end
      if not value and type(err) == "string" and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end
   assert(value == nil and type(err) == "table")

   while true do
      value, err = devicetree.get("unexisting_node")
      if not value and err ~= "error 517 [hint: ipc broken]" then break end
      sched.wait(1)
   end
   assert(err == "handler not found")
end

function t :test_dt_Unregister()
   while true do
      local status, err = devicetree.unregister(regId)
      if status and not err then break end
      if not status and err ~= "error 517 [hint: ipc broken]" then assert(nil) end
      sched.wait(1)
   end
end

return t
