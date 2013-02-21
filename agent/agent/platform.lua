-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

--- ReadyAgent port on Linux : porting and wrappers functions

global 'agent'
agent = agent or { }
agent.platform = { }

--------------------------------------------------------------------------------
-- platform.init must return non false/nil value for success
-- or nil+error message
function agent.platform.init()

    -- getdeviceid() isn't defined:
    -- the device's M2MOP id must be set in config's
    -- agent.config.agent.deviceId

    -- Returns the map feature/version of features provided by the
    -- platform to the update manager
    global 'getupdateplatformcomponent'
    function getupdateplatformcomponent()
        local get = require "agent.treemgr".get
        return {
            ReadyAgent    = _READYAGENTRELEASE,
        }
    end


    return "ok"
end

return agent.platform

