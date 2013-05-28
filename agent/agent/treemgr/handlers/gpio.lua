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

local gpio    = require"gpio"
local log     = require"log"
local upath   = require"utils.path"
local treemgr = require"agent.treemgr"

--the name used to load this tree handler, to be used for notification
local handlername = ... 

local logmod= "DT-GPIO"

local M = { }

function M :get (path)
    local res, err
    if path == nil or path == "" then --list gpio path
        res, err = gpio.enabledlist() -- list of available GPIOs.
        if not res or type(res)~= "table" then return nil, err or "error while loading GPIO list"
        else
            local res2 = {}
            for k,v in pairs(res) do res2[v]=true end
            --no need to set real value, available GPIOs will be return when explicitly requested
            res2.available = true
            return nil, res2
        end
    elseif path == "available" then
        local res, err = gpio.availablelist()
        if not res then return nil, err or "Can't get availablelist"
            --return it as a string so that no subvalue will be requested.
        else return sprint(res) end
    else
        local id, subpath = upath.split(path,1)
        id = tonumber(id)
        if not id then return nil, "invalid GPIO id" end
        if not subpath or subpath == "" then --list subpath for a given GPIO
            return nil, { value=true, direction=true, edge=true, activelow=true}
        elseif subpath == "value" then --actually read GPIO value
            return gpio.read(id)
        elseif subpath == "direction" or subpath == "edge" or subpath == "activelow" then
            -- those subpaths are only for configuration purpose
            res, err = gpio.getconfig(id)
            if not res or type(res)~= "table" then return nil, err or "failed to get GPIO config" end
            if not res[subpath] then
                return nil, string.format("failed to get GPIO config field %s", tostring(subpath))
            else
                return res[subpath]
            end
        else
            return nil, string.format("invalid GPIO parameter: %s", tostring(subpath))
        end
    end
end

function M :set(hmap)
    local res,err
    for hpath, val in pairs(hmap) do
        local id, subpath = upath.split(hpath,1)
        id = tonumber(id)
        if not id then return nil, "invalid GPIO id" end
        if subpath == "value" then
            val = tostring(val)
            if val ~= "0" and val~="1" then return nil, string.format("invalid value %s", val) end
            res,err = gpio.write(id, val)
            if not res then return nil, string.format("error when writing to %d: err:%s", id, err) end
        elseif subpath == "direction" or subpath == "edge" or subpath == "activelow" then
            val = tostring(val)
            if not val then return nil, string.format("invalid value %s for parameter %s", val, subpath) end
            res, err = gpio.configure(id, { [subpath]=val})
            if not res then return nil, string.format("error when configuring GPIO %d: err: %s", id, tostring(err)) end
            --TODO: improvement: bufferize cfg actions?
        else
            return nil, string.format("invalid GPIO parameter: %s", tostring(subpath))
        end
    end
    return "ok"
end


--keep track of registered GPIOs
--to prevent useless multi registrations.
local registered = {}


local function gpio_hook(id, val)
    id = tonumber(id)
    if not id then
        log(logmod, "WARNING", "Receive notification from gpio module with invalid id ")
    elseif not registered[id] then 
        log(logmod, "WARNING", "Receive notification from gpio module for 'unknown' id.")
    else
        --id = tostring(id)
        local path = string.format("%d.value", id)
        treemgr.notify(handlername, { [path]=val});
    end
end


function M :register(hpath)
    local id, subpath = upath.split(hpath,1)
    id = tonumber(id)
    if not id or subpath ~= "value" then return nil, "only GPIO value can be monitored" end
    if not registered[id] then
        registered[id] = true
        return gpio.register(id, gpio_hook)
    else
        return "ok"
    end
end


function M :unregister(hpath)
    local id, subpath = upath.split(hpath,1)
    id = tonumber(id)
    if subpath ~= "value" then return nil, "only GPIO value can be monitored" end
    if registered[id] then
        registered[id] = nil
        return gpio.register(id, nil)
    else
        return "ok"
    end
end

return M
