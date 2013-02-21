-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Cureo Bugot for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------
-- This module provides the Monitoring Service into the agent.
-- See Monitoring documentation for the script syntax. A monitoring script is merely a configuration object that describes some
-- monitoring behavior.
--
-- install(name, script, [autoenable])
--      Install a script with the given name. script must be a string or string buffer (table) containing the Monitoring Script,
--              or a regular function that will be dumped (so no up values are autorised !)
--      autoenable is an optional boolean parameter stating if the script must be enabled or not (see enable/disable function).
--              autoenable can be set to the value "now" to load the script instantaneously. When set to "now" the script is
--              not stored into persisted storage, and thus will not be restarted on next reboot.
--      A script is installed but not started or enabled by default. At startup (or after a reboot) all the installed and
--              enabled scripts are loaded.
--      Installing a script with the same name will overwrite the stored script. If a script is overwritten and autoenable
--              parameter is omitted, then the enable flag for that script is kept unchanged.
--      Returns "ok" in case of success, nil followed by the error otherwise.
--
-- uninstall(name)
--      Uninstall the script that has the given name. The script is erased from the system, but not stoped until the next boot
--              sequence.
--      Returns "ok" in case of success, nil followed by the error otherwise.
--
-- enable(name)
--      Enable the script that has the given name. Enabling a script will allow the script to be started on next boot sequence.
--      Returns "ok" in case of success, nil followed by the error otherwise.
--
-- disable(name)
--      Disable the script that has the given name. Disabling a script will prevent the script from being started on next boot
--              sequence. Disabling a script will not stop it synchronously. Disabling a script does not remove it from the
--              system (see uninstall)
--      Returns "ok" in case of success, nil followed by the error otherwise
----------------------------------------------------------------------------------------------------------------------------------


local require = require
local sched = require "sched"
require "coxpcall"
local timer = require "timer"
local server = require "agent.srvcon"
local persist = require "persist"
local device = require "agent.devman"
local config = require "agent.config"
local tableutils = require "utils.table"
local pathutils = require "utils.path"
local loader = require"utils.loader"
local log = require "log"
local copcall = copcall
local pcall = pcall
local tonumber = tonumber
local setmetatable = setmetatable
local getmetatable = getmetatable
local setfenv = setfenv
local pairs = pairs
local ipairs = ipairs
local next = next
local table = table
local type = type
local assert = assert
local loadstring = loadstring
local os = os
local math = math
local string = string
local error = error
local _G = _G
local try = socket.try
local protect = socket.protect
local rawget = rawget
local rawset = rawset
local debug = debug
local unpack = unpack

module(...)

vars = {}               -- Holds monitored tables


-- For the following tables a variable is identified by its "full" path. ex: "system.celluar.rssi"
local cvhooks = {}      -- holds the list of hooks to call for a given variable hooks[variable] = {hook0, hook1, ...}
                        -- if there is only one hook on a variable then it is in the form hooks[variable] = hook
local xvpushen = {}     -- enable asynchronous push for a given external variable (necessary when using onchange() and alike triggers)
local xvwrite = {}      -- enable the call of a function in order to write back a variable

-- return the value of a monitored variable. (ex: 'system.cellular.rssi')
--    table is the monitored table that hold the variable, (ex system.cellular)
--    var is the name the variable (not repeating the path) (ex: 'rssi')
local function cvgetvar(table, var)
    local store = rawget(table, "__store")
    local val = (store and store[var])
    if val == nil then val = rawget(table, "__getvar") end
    if type(val) == "function" then val = val(rawget(table, "__path"), var) end
    return val
end
-- Set a variable value and call associated hooks if any.
-- path and var are defined as for cvgetvar() function
local function cvsetvar(table, var, val)

    local path = rawget(table, "__path")
    local fqvn = path..var
    local write = xvwrite[fqvn] or xvwrite[path]
    if write then write(path, var, val) end

    if val == table[var] then return end -- do not call hooks if the value is the same !

    local store = rawget(table, "__store")
    store = store or rawset(table, "__store", {}).__store
    store[var] = val -- store the given value


    local function call(hooks)
        if hooks then
            if type(hooks) == "function" then hooks(nil, fqvn)
            else -- hook is a table of hooks
                for _, f in ipairs(hooks) do f(nil, fqvn) end
            end
        end
    end
    call(cvhooks[fqvn])
    call(cvhooks[path])
end

-- return the holding table and name of the variable (given its full qualified name) so it can be used to regularly retreive the value of the variable
local function getmontable(var)
    local path, varname = pathutils.split(var, -1)
    local t = pathutils.find(vars, path)
    return t, varname
end


-- Register a hook that is called whenever one of the variables in vars changes
local function cvregister(vars, hook)
    for _, v in ipairs(vars) do
        if type(v) ~= "string" then error("variable names must be strings") end
        local h = cvhooks[v]
        if not h then
            cvhooks[v] = hook
            local path, varname

            if v:sub(-1) == '.' then path = v:sub(1, -2) -- to be optimized, removed the '.' and re append later on...
            else path, varname = pathutils.split(v, -1) end

            if path == "" or pathutils.split(path, 1) == "" then return error("bad variable name") end
            path = path..'.'
            local pushenable = xvpushen[v] or xvpushen[path]
            if pushenable then -- is there any function to call in order to enable automatic pushing of that variable?
                xvpushen[v] = nil -- do not need this function anymore
                pushenable(path, varname) -- enable async push for the external variable
            end

            local mt = getmontable(v)
            local store = rawget(mt, "__store") or rawset(mt, "__store", {}).__store
            if mt then
                -- if there is a getvar for this variable -> fix the variable to a regular value (new values will be pushed in)
                if varname then
                    local f = store[varname]
                    if f == nil then f = rawget(mt, "__getvar") end
                    if type(f) == 'function' then
                        f = f(path, varname)
                        store[varname] = f == nil and function() end or f -- make sure the var will return nil and do not call a possible __getvar fallback
                    end
                else
                -- if there is a getvat / varlist for a group then they need to be disabled (the whole group is in push mode)
                    local getvar = rawget(mt, "__getvar")
                    if getvar then
                        local list = rawget(mt, "__list")
                        if type(list) == "function" then list = list(rawget(mt, "__path")) end
                        for _, k in ipairs(list) do
                            local v = getvar(path, k)
                            store[k] = v
                        end
                    end
                    -- disable poll mode
                    rawset(mt, "__list", nil)
                    rawset(mt, "__getvar", nil)
                end
            end

        elseif type(h) == "function" then
            cvhooks[v] = {h, hook}
        else -- we already have a table
            table.insert(h, hook)
        end
    end
end



local function cvpairs(table)
    local keys = {}

    -- get variables from the list
    local list = rawget(table, "__list")
    if list then
        if type(list) == "function" then list = list(rawget(table, "__path")) end
        if type(list) == "table" then
            for _, k in ipairs(list) do keys[k] = true end
        end
    end

    -- get variables from store
    local store = rawget(table, "__store")
    if store then for k, _ in pairs(store) do keys[k] = true end end

    -- get subtables/non monitored variables
    for k, v in next, table do
        if not k:match("^__") then keys[k] = true end
    end

    local function iterate(t, k)
        local v
        repeat
            k = next(t, k)
            v = table[k]
        until v or not k

        if k then return k, v end
    end

    return iterate, keys, nil
end


-- Track a table. A tracked table call the hook whenever v changes (see cvregister)
local trackedtablemt = {
    __index = cvgetvar,
    __newindex = cvsetvar,
    __pairs = cvpairs
}
local function cvtrackedtable(path, t)
    t = t or {}
    -- t.__store={} store is created when needed (i.e. the variable is written) !
    t.__path = path.."."
    return setmetatable(t, trackedtablemt)
end



-- This function allows to add additional variables in the monitored tables
--  pushenable and getvar are functions. pushenable will be called by the monitoring engine in order to enable asynchronous mode
--  getvar will be called if asynchronous push mode is not enabled and the variable is read.
--  varlist argument must be provided only when registering group of variables. varlist must be either a table (array) that list the names
--      of the variables, or a function that returns that table.
-- When successful, this function returns the table that holds the monitored variable or group of variables
-- notes:
--  if pushenable is a string or a number, then getvar is ignored and the value of pushenable is set as a static value into the monitoring variable table
--  pushenable and getvar can be equal to nil, restricting the usage of that variable, according to what is nil
--  var can actually a path designating a group of variables, in that case it must have a trailing '.'. ex 'system.cellular.'
--  the actual tables will be automatically created by this function
--  pushenable and getvar, when defined as functions will be called with two parameters: the path, and the variable name. pushenable may be called
--      with a nil variable name, meaning the pushenable is on the whole group (=path) of variable.

function registerextvar(var, pushenable, getvar, varlist, setvar)

    -- inputs check
    assert(type(var) == "string", "var name must be a fdqn variable or groupe name")
    local path, varname
    local groupmode -- true when the register is on a group rather than a single variable
    if var:sub(-1) == '.' then
        groupmode = true
        path = var:sub(1, -2)
    else
        path, varname = pathutils.split(var, -1)
    end
    if path == "" or  pathutils.split(path, 1) == "" then
        return error(string.format("invalid path in variable [%s]", var))
    end
    
    local tpe = type(pushenable)
    local constvar = tpe=="string" or tpe=="number" or tpe=="boolean"
    assert(not constvar or not (getvar or valist), "no getvar or varlist should be provided for constant variables")
    assert(not groupmode or not constvar, "not possible to set a const val for a group")
    assert(not groupmode or not pushenable or tpe=="function", "pushenable must be a function for group variables")
    assert(not pushenable or constvar or tpe=="function", "pushenable must be a constant value or a function")
    assert(not getvar or type(getvar)=="function", "getvar param must be a function (when provided)")
    assert(not groupmode or not varlist or type(varlist)=="function" or type(varlist)=="table", "varlist must be a table or a function returning a table")
    assert(groupmode or pushenable or getvar or setvar, "need either a non nil pushenable or getvar or setvar for registering a variable")
    assert(not varlist or groupmode, "cannot define a varlist for a single variable")
    assert(not varlist or getvar, "need to define a getvar if providing a varlist")
    assert(setvar == nil or type(setvar)=='function', "When defined, setvar must be a function")


    -- create the path to store the new variable(s)
    local p = pathutils.segments(path)
    local table = vars
    for _, n in ipairs(p) do
        local nt = rawget(table, n)
        nt = nt~=nil and nt or {}
        if type(nt)~='table' then
            return error(string.format("[%s] would overwrite an existing variable", var))
        end
        rawset(table, n, nt)
        table = nt
    end
    -- make the table monitorable
    if not getmetatable(table) then cvtrackedtable(path, table) end

    -- keep the setvar hook if any
    xvwrite[var] = setvar

    if constvar then -- do we have a const value ?
        table[varname] = pushenable
        xvpushen[var] = nil
    else
        xvpushen[var] = pushenable
        if groupmode then
            rawset(table, "__getvar", getvar)
            rawset(table, "__list", varlist)
        else
            table[varname] = getvar
        end
    end

    return table
end


-- Monitoring Global tables
-- user is a monitored table that holds user defined variables
-- system is a monitored table that holds system variables
-- persist is a NON monitored table that holds persisted data (survive reboot)
-- global is a NON monitored table and NON persisted table. Holds user defined data...
vars.user = cvtrackedtable("user")
vars.system = cvtrackedtable("system")
vars.global = {}
vars.persist = persist.table.new("MonitoringStore")

-- table that holds the monitoring script function common to setup and exec environement
local commonenv = {
     -- general tables
    user = vars.user, system = vars.system, config = config, global = vars.global, persist = vars.persist,
    -- standard libraries
    os = os, math = math, string = string,
    -- utility functions
    time = os.time, print = _G.print}

-- table that holds the monitoring script setup environement
local setupenv = setmetatable({require = require}, {__index = commonenv})
-- table that holds the triggers and action functions execution environement
local execenv = setmetatable({}, {__index = commonenv})

-- Check if hooks are filtered or bypassed
local function testfilters(hooks)
    if hooks.filter then
        if type(hooks.filter) == "function" then
            local s, v = pcall(hooks.filter)
            -- if error while executing, log error but default filter value is true
            if not s then log("MONITORING", "ERROR", "Error while executing a monitoring filter: %s", v)
            elseif not v then return false end
        else
            for _, f in ipairs(hooks.filter) do
                local s, v = pcall(f)
                -- if error while executing, log error but default filter value is true
                if not s then log("MONITORING", "ERROR", "Error while executing a monitoring filter: %s", v)
                elseif not v then return false end
            end
        end
    end
    return true
end

-- Call the hooks from the table (regardless of filters)
-- Call the hooks in an ordered manner
local function callhooks(hooks, ...)
    for _, f in ipairs(hooks) do
        local s, e = copcall(f, ...)
        if not s then log("MONITORING", "ERROR", "Error while executing a monitoring action: %s", e) end
    end
end

-- Simple functor that is used several times. This prevent from declaring many times the same anonymous function (save space...)
local function actioncaller(actions)
    local function f(ev, ...)
        if testfilters(actions) then -- execute the filtering function synchronously
            sched.run(callhooks, actions, ...)
        end
    end
    return f
end

local onboothooks = {}
local onconnecthooks = {}

-- Create the pre-connect hook. It will be called before a connection to the server is established
function server.preconnecthook()
    -- we do not use actioncaller here because actions need to be done synchronously
    for _, actions in ipairs(onconnecthooks) do
        if testfilters(actions) then callhooks(actions) end
    end
end

--------------------------------------------------------------------------------------------
-- predefined triggers
--------------------------------------------------------------------------------------------

-- Activated when one of the variable from the list changes
-- ... is a variable number of variable to monitor, named as string: ex "system.batterylevel", "user.somevar", ....
function setupenv.onchange(...)
    local vars = {...}
    assert(#vars >= 1, "must hook on variable(s)")
    local actions = {}
    cvregister(vars, actioncaller(actions))
    return actions
end

-- activated when none of the variables change for the timeout amount of time
--    if timeout > 0 then once activated, the trigger is re-armed only when a variable changes.
--    if timeout < 0 then the trigger is automatically re-armed
-- ... is a list of variable as strings.
function setupenv.onhold(timeout, ...)
    local t = timer.new(tonumber(timeout))
    local last
    local varname = ...
    local function rearm(_, v)
        timer.cancel(t)
        timer.rearm(t)
        last = v
    end
    cvregister({...}, rearm)
    local actions = {}
    sched.sighook(t, "*", function() actioncaller(actions)(nil, last) end)
    return actions
end

function setupenv.onperiod(period)
    local p = tonumber(period)
    assert(p > 0, "period must be a positive number")
    local t = timer.new(-p) -- start a periodic timer
    local actions = {}
    sched.sighook(t, "*", actioncaller(actions))
    return actions
end

function setupenv.ondate(cron)
    assert(type(cron)=="string", "cron pattern must be a string")
    local t = timer.new(cron) -- start a cron timer
    local actions = {}
    sched.sighook(t, "*", actioncaller(actions))
    return actions
end

function setupenv.onboot()
    local actions = {}
    table.insert(onboothooks, actions)
    return actions
end

function setupenv.onconnect()
    local actions = {}
    table.insert(onconnecthooks, actions)
    return actions
end

function setupenv.onrecvcmd(cmdnamepattern)
    error "Feature in disrepair, stay tuned."
    cmdnamepattern = cmdnamepattern or ''
    local actions = {}
    local hl = assert(false, "AWTDAHL deprecated") -- require 'awtdahl'
    local function recv(ev, m)
        local messageType, path, content, needToAck = hl.parsemessage(m)
        if messageType == 'Command' and path == 'monitoring' then
            local cmd = content.command
            if cmd:match(cmdnamepattern)  then
                actioncaller(actions)(nil, cmd, unpack(content.args))
                if needToAck then
                    local function ack(m)
                        local server = require 'agent.srvcon'
                        local hl = assert(false, "AWTDAHL deprecated") -- require 'awtdahl'
                        hl:sendacknowledgement(m)
                        server.connect(true)
                    end
                    sched.run(ack, m)
                end -- auto ack handled commands
            end
        end
    end
    THIS_WONT_WORK = sched.sighook(device.hl, "Message", recv)
    return actions
end

--------------------------------------------------------------------------------------------
-- derived triggers
--------------------------------------------------------------------------------------------


-- activated when a value traverse a threshold (previous and new value are opposite side of the threshold value)
-- when edge is specified it can be one of "up" or "down" meaning only triggering on rising edge or falling edge
--      an up edge is detected when oldval<threshold and newval>=threshold
--      a down edge is detected when oldval>=threshold and newval<threshold
function setupenv.onthreshold(threshold, var, edge)
    local mt, varname = getmontable(var)
    local side = (mt[varname] or 0) < threshold
    local up = not edge or edge=="up"
    local down = not edge or edge=="down"
    local function test()
        local newval = mt[varname] or 0
        if (newval>=threshold and side) or (newval<threshold and not side) then
            local r = (up and side) or (down and not side)
            side = newval < threshold
            return r
        else return false end
    end
    return setupenv.filter(test, setupenv.onchange(var))
end


-- activated when a values goes outside a limited range: activated if abs(newval-oldval) >= deadband
-- oldval is updated when the trigger is activated
function setupenv.ondeadband(deadband, var)
    local mt, varname = getmontable(var)
    local oldval = mt[varname] or 0
    local function test()
        local newval  = mt[varname] or 0
        local d = math.abs(newval - oldval)
        if d >= deadband then
            oldval = newval
            return true
        else return false end
    end
    return setupenv.filter(test, setupenv.onchange(var))
end


--------------------------------------------------------------------------------------------
-- filter function
--------------------------------------------------------------------------------------------

function setupenv.filter(test, actions)
    -- save a table if there is only one function filter
    if not actions.filter then
        actions.filter = test
    elseif type(actions.filter) == "function" then
        local f = actions.filter
        actions.filter = {f, test}
    else
        table.insert(actions.filter, test)
    end
    return actions
end

--------------------------------------------------------------------------------------------
-- predefined actions
--------------------------------------------------------------------------------------------

-- Connect To Server action
-- latency is a positive number that indicate the tolerated latency for the server connection.
-- This means that an actual connection is guaranted to happen in at most latency seconds
-- giving a nil value will cause a synchronous connection to server
execenv.connecttoserver = server.connect


function execenv.sendcorrelateddata(path, data)
    return device.hl:sendcorrelateddata(path, data)
end
function execenv.sendtimestampeddata(path, data)
    return device.hl:sendtimestampeddata(path, data)
end
function execenv.sendevents(path, events)
    return device.hl:sendevents(path, events)
end

--------------------------------------------------------------------------------------------
-- connector function
--------------------------------------------------------------------------------------------

function setupenv.connect(trigger, action)
    assert(action and type(action) == 'function', "the provided action must be a function")
    if trigger[action] then return end -- connection can only be done once for the same couple of action trigger
    trigger[action] = true
    table.insert(trigger, action)
end

--------------------------------------------------------------------------------------------
-- monitoring scripts management
--------------------------------------------------------------------------------------------
local scriptlist -- list of installed scripts, value is boolean for enabled/disabled

local function loadscript(name, script)
    local s
    s = script or persist.load("monitoring."..name) or error("script not existing")
    local t = type(s)
    if t == "function" then -- nothing to do the function will be called below
    elseif t == "string" then s = try(loadstring(s, name))
    elseif t == "table" then s = try(loader.loadbuffer(s, name, true))
    else error("bad script") end
    local env = setmetatable({__scriptname=name}, {__index=setupenv})
    setfenv(s, env)
    s()
    return setmetatable(env, {__index=execenv})
end
loadscript = protect(loadscript) -- make the function return nil, err instead of rising lua errors


function init()
    if scriptlist then return "ok" end

    if config.monitoring.debug then setmetatable(commonenv, {__index=_G}) end -- Allows to "see" all global variables in monitoring scripts

    scriptlist = persist.table.new("MonitoringScriptList")
    vars.scriptlist = scriptlist

    for name, enabled in tableutils.sortedpairs(scriptlist) do
        if enabled then
            local s, err = loadscript(name)
            if not s then log("MONITORING", "ERROR", "Error while loading script %s, err=%s", name, err) end
        end
    end

    -- Trigger the onboot event, 30 seconds after the initialization
    sched.sigonce("*", 30, function() for _, actions in ipairs(onboothooks) do actioncaller(actions)() end end)

    -- Register Device management Data read/write
    -- local tm = require 'agent.treemgr'
    -- tm.handlers.monitoring = vars
    -- TODO: register `agent.monitoring.treemgr_handler` in the tree map.

    return "ok"
end


function install(name, script, autoenable)
    -- Allows giving direct function as script, but to be sure not to have side effects, the function is first dumped (anyway it will be stored dumped)
    if autoenable == "now" then return loadscript(name, script) end
    if type(script) == 'function' then
        if debug.getinfo(script, "u") ~= 0 then error "function script must not have upvalues" end
        script = assert(string.dump(script))
    end
    persist.save("monitoring."..name, script)
    if autoenable == nil then autoenable = scriptlist[name] end -- take the existing value if unset
    autoenable = autoenable and true or false -- make it a real boolean !
    scriptlist[name] = autoenable
    return "ok"
end

function uninstall(name)
    if scriptlist[name] == nil then return nil, "script not existing" end
    scriptlist[name] = nil
    persist.save("monitoring."..name, nil)
    return "ok"
end

function uninstallall()
    for name in pairs(scriptlist) do persist.save("monitoring."..name, nil) end
    persist.table.empty(scriptlist)
    return "ok"
end

function enable(name)
    if scriptlist[name] == nil then return nil, "script not existing" end
    scriptlist[name] = true
    return "ok"
end

function disable(name)
    if scriptlist[name] == nil then return nil, "script not existing" end
    scriptlist[name] = false
    return "ok"
end




