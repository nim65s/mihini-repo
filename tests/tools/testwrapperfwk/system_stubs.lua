-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local sched  = require 'sched'

local function remote_patching()
   local rpc = require 'rpc'

   local client = rpc.newclient()
   if not client then
      print("Ready agent not started")
      return
   end

   local init_config = client:newexec(function(...)
					 require "agent.system"
					 package.loaded["agent.system"].reboot = function(delay)
					    local sched = require 'sched'
					    delay = ((tonumber(delay) or 5) > 5) and tonumber(delay) or 5
					    sched.signal("system", "stop", "reboot")
					    sched.run(function() sched.wait(delay); print("system_stubs: rebooting...") end)
					 end
				      end)
   init_config()
   sched.signal("module", "done")
end

sched.run(remote_patching)
