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

local config = require"agent.config"
local pathutils = require"utils.path"
local lfs=require"lfs"
local niltoken = require"niltoken"

local devman = require"agent.devman"
local devasset = devman.asset


local M = {}

local installscript
local appconinstall

-- run internal installers
local function dispatch( name, version, path, parameters)
    local res        
    local updatepath , _ = pathutils.split(name, -1)
    
    if not updatepath then
        log("UPDATE", "INFO", "BUILTIUPDATE for package %s: Update path is not valid", tostring(name))
        return 473      
    end
    --dispatch the update
    if updatepath=="update" then
        log("UPDATE", "INFO", "BUILTIUPDATE:installscript is running for component %s, path=%s", tostring(name), tostring(path))
        res = installscript(name, version, path, parameters)
    elseif updatepath=="appcon" then
        log("UPDATE", "INFO", "BUILTIUPDATE:appcon is running for component %s, path=%s", tostring(name), tostring(path))
        res = appconinstall(name, version, path, parameters)
    else
        log("UPDATE", "INFO", "BUILTIUPDATE for package %s: Sub path is not valid", tostring(name))
        res = 473
    end

    return res
end

function installscript(name, version, path, parameters)
    if not path then 
         log("UPDATE", "DETAIL", "BUILTIUPDATE:running install script with no location given, immediate success")
    return 200 end
    
    local scriptpath = path.."/install.lua"
    if not lfs.attributes(scriptpath) then
        log("UPDATE", "ERROR", "BUILTIUPDATE:installscript for package %s: file install.lua does not exist", name)
        return 474
    end
    local f, err = loadfile(scriptpath)
    if not f then
        log("UPDATE", "ERROR", "BUILTIUPDATE:installscript for package %s: Cannot load install.lua script, err=%s",name,  err or "nil")
        return 475
    end
    
    --parameters given to the install to ease its work, add other parameters in the param table, so that API is kept.
    local runtimeparams = {cwd = lfs.currentdir(),  script_dir = path, name = name, version = version, parameters = parameters}
    
    local res, err = copcall(f, runtimeparams)
    if not res then
        log("UPDATE", "ERROR", "BUILTIUPDATE:installscript for package %s: script execution error, err=%s", name, err or "nil");
        return 476
    end

    return 200
end

function appconinstall(name, version, appdata, parameters)
    if not config.get('appcon.activate') then
        log("UPDATE", "ERROR", "BUILTIUPDATE:ApplicationContainer updater cannot be run because ApplicationContainer is not activated!")
        return 477 end   
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
    log("UPDATE", "INFO", "BUILTIUPDATE:ApplicationContainer updater result: res=%s, err=%s", tostring(res), tostring(err))
    return res and 200 or 478
end

M.dispatch = dispatch

return M;