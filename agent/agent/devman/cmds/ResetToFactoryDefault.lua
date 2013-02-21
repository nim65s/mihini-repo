-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
--     Romain Perier      for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local checks = require 'checks'

local function ResetToFactoryDefault(asset, params, command, ticketid)
    checks("?", "?table", "?", "number")

    local restart = params and params[1] or nil

    --ResetToFactoryDefault is done with a list a directories to remove
    --Removing the whole LUA_AF_RW_PATH directory is not possible for
    --default installation where LUA_AF_RW_PATH and LUA_AF_RO_PATH are the same
    --folder, so it would end up removing RA binaries too.

    --directories to delete
    local directories={
        --Lua Fwk:
        persistdir  =(LUA_AF_RW_PATH or "./").."persist",
        --logdir    =log dir is configurable! So it is hard

        --ReadyAgent modules:
        updatedir   =(LUA_AF_RW_PATH or "./").."update/",
        appcondir   =(LUA_AF_RW_PATH or lfs.currentdir().."/").."apps/"
        --config is using persist dir
        --treemgrdir= is using persist dir
        --security credentials are *not* cleared
    }

    local status, output
    local result = 0 -- = 1 if one delete command fails
    for k,v in pairs(directories) do
        status, output = require "utils.system".pexec("rm -rf "..v)
        if status ~= 0 then
            log("DEVMAN", "WARNING", "ResetToFactoryDefault: operation failed for=%s", tostring(v))
            result = 1
        end
    end

    local log = require 'log'
    log("DEVMAN", "INFO", "Agent settings have been reset to factory, result = %s", result == 0 and "ok" or "ko")
    if (type(restart) == "boolean" and restart) or (type(restart) == "number" and restart) then
        local delay = (type(restart) == "number" and restart >= 6 and restart) or 6
        log("DEVMAN", "INFO", "Requesting Agent to be restarted in "..tostring(delay).." seconds")
        --this also depends on ReadyAgent integration:
        -- if it is started using AppmonDaemon, making ReadyAgent exiting with code !=0 may be enough
        -- (however the application installed in ApplicationContainer are likely to be still running)
        -- anyway, rebooting the whole device operating system is recommended.
        require 'agent.system'.reboot(delay)
    end
    require 'racon'.acknowledge(ticketid, result, nil, 'now', 0)
    return "async"
end

return ResetToFactoryDefault
