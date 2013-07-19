-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

--
-- This file provides the installation of components from an update package sending the update to the agent (@sys).
-- For now two types of update are accepted:
--  - @sys.appcon: manage (install/uninstall) an application in the ApplicationContainer module
--  - @sys.update: `install script`: run a simple Lua script embedded in the update package
--

local config = require"agent.config"
local pathutils = require"utils.path"
local lfs=require"lfs"
local niltoken = require"niltoken"

local devman = require"agent.devman"
local devasset = devman.asset
local errnum = require 'agent.update.status'.tonumber

local M = {}

local installscript
local appconinstall

-- run internal installers
local function dispatch( name, version, path, parameters)
    local res
    local updatepath , _ = pathutils.split(name, -1)

    if not updatepath then
        log("UPDATE", "INFO", "Built-in update for package %s: Update path is not valid", tostring(name))
        return errnum 'BAD_PARAMETER'
    end
    --dispatch the update
    if updatepath=="update" then
        log("UPDATE", "INFO", "Built-in update: installscript is running for component %s, path=%s", tostring(name), tostring(path))
        res = installscript(name, version, path, parameters)
    elseif updatepath=="appcon" then
        log("UPDATE", "INFO", "Built-in update: appcon is running for component %s, path=%s", tostring(name), tostring(path))
        res = appconinstall(name, version, path, parameters)
    else
        log("UPDATE", "INFO", "Built-in update for package %s: Sub path is not valid", tostring(name))
        res = errnum 'BAD_PARAMETER'
    end

    return res
end

function installscript(name, version, path, parameters)
    if not path then
         log("UPDATE", "DETAIL", "Built-in update: running install script with no location given, immediate success")
    return errnum 'OK' end

    local scriptpath = path.."/install.lua"
    if not lfs.attributes(scriptpath) then
        log("UPDATE", "ERROR", "Built-in update: installscript for package %s: file install.lua does not exist", name)
        return errnum 'BAD_PARAMETER'
    end
    local f, err = loadfile(scriptpath)
    if not f then
        log("UPDATE", "ERROR", "Built-in update: installscript for package %s: Cannot load install.lua script, err=%s",name,  err or "nil")
        return errnum 'IO_ERROR'
    end

    --parameters given to the install to ease its work, add other parameters in the param table, so that API is kept.
    local runtimeparams = {cwd = lfs.currentdir(),  script_dir = path, name = name, version = version, parameters = parameters}

    local res, err = copcall(f, runtimeparams)
    if not res then
        log("UPDATE", "ERROR", "Built-in update: installscript for package %s: script execution error, err=%s", name, err or "nil");
        return errnum 'UNSPECIFIED_ERROR'
    end

    return errnum 'OK'
end

function appconinstall(name, version, appdata, parameters)
    if not config.get('appcon.activate') then
        log("UPDATE", "ERROR", "Built-in update: ApplicationContainer updater cannot be run because ApplicationContainer is not activated!")
        return errnum 'NOT_AVAILABLE' end
    local appcon = require"agent.appcon"
    --name = appcon.some.thing, let's remove "appcon" from name
    local _, appname = pathutils.split(name, 1)
    local res, err
    if version then --filter extra parameters
        local purge = parameters and parameters.purge==true
        local autostart = parameters and parameters.autostart == true
        res, err = appcon.install(appname, appdata, autostart, purge)
    else
        res, err = appcon.uninstall(appname)
    end
    log("UPDATE", "INFO", "Built-in update: ApplicationContainer updater result: res=%s, err=%s", tostring(res), tostring(err))
    return errnum (res and 'OK' or 'UNSPECIFIED_ERROR')
end

M.dispatch = dispatch

return M;