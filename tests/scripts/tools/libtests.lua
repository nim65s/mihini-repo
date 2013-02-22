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

-- library used to test the ReadyAgent
local sched = require 'sched'
local awtdahl = assert(false, "AWTDAHL has been deprecated")

-- Create an asset for software update using AWTDA
-- Use some local data to keep values
local assetSoftwareUpdate = nil
local assetUpdated = false
local hook = nil

local function TST_AWTDA_Callback(m, instance)
    local messageType, path, content, needToAck = awtdahl.parsemessage(m)

    -- process the message
    if (messageType == "Command") then

        -- Execute the specified command
        if (content.command == "SoftwareUpdate") then

        end

    elseif (messageType == "CorrelatedData") then

    end

    -- return ack if necessary
    if needToAck then
        assetSoftwareUpdate:sendacknowledgement(m)
    end

    --send commands
    assetSoftwareUpdate.com:connecttoserver()
    assetUpdated = true
    return "again"
end

-- Create an asset for software update using AWTDA
function TST_createassetSU()
    local assetId = "AssetSoftwareUpdate"
    assetSoftwareUpdate = airvantage.newasset(assetId)
    if not assetSoftwareUpdate then return false, "Cannot create asset" end
    hook = sched.sighook({assetSoftwareUpdate}, "*", TST_AWTDA_Callback)
    assetSoftwareUpdate:start()
    assetUpdated = false

    return true
end

function TST_isassetupdated()
    return assetUpdated
end
