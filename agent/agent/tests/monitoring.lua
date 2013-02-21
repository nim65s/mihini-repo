-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Cuero Bugot        for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local mon = require'agent.monitoring'
local u = require 'unittest'
local config = require 'agent.config'



local t=u.newtestsuite("monitoring")

local ran

function t:setup()
    if ran then u.abort("This unit test need to restart the environement") end
    ran = true
end

function t:test_config()
    u.assert_table(config.monitoring)
    u.assert_true(config.monitoring.activate)
    u.assert(not config.monitoring.debug)
end

function t:test_regextvarerrors()
    local stub = function() end
    u.assert_error(function() mon.registerextvar("system.test1") end)
    u.assert_error(function() mon.registerextvar("system.test1", stub, stub, stub) end)
    u.assert_error(function() mon.registerextvar("system", stub, stub) end)
    u.assert_error(function() mon.registerextvar("system.test1.", stub, nil, stub) end)
end

function t:test_regextvarok()
    local stub = function() end
    u.assert_table(mon.registerextvar("system.tests."))
    u.assert_table(mon.registerextvar("system.tests.t1", stub))
    u.assert_table(mon.registerextvar("system.tests.t2", nil, stub))
    u.assert_table(mon.registerextvar("system.tests.t3", stub, stub))
    u.assert_table(mon.registerextvar("user.tests."))
    u.assert_table(mon.registerextvar("user.tests.t1", stub))
    u.assert_table(mon.registerextvar("user.tests.t2", nil, stub))
    u.assert_table(mon.registerextvar("user.tests.t3", stub, stub))
    u.assert_table(mon.registerextvar("sometable.tests."))
    u.assert_table(mon.registerextvar("sometable.tests.t1", stub))
    u.assert_table(mon.registerextvar("sometable.tests.t2", nil, stub))
    u.assert_table(mon.registerextvar("sometable.tests.t3", stub, stub))
end

function t:test_regextvar_pushenable()
    local called
    local function pushenable(path, varname)
        called = path..(varname or "")
    end
    local t = mon.registerextvar("system.tests.t4", pushenable)
    u.assert_table(t)
    u.assert_table(mon.install("test", "onchange'system.tests.t4'", "now"))
    u.assert_equal("system.tests.t4", called)

    t = mon.registerextvar("system.tests.", pushenable)
    u.assert_table(t)
    u.assert_table(mon.install("test", "onchange'system.tests.t5'", "now"))
    u.assert_equal("system.tests.t5", called)

    u.assert_table(mon.install("test", "onchange'system.tests.'", "now"))
    u.assert_equal("system.tests.", called)
end

function t:test_regextvar_getvar()

    local function getvar(path, varname) return path..(varname or "") end

    local t = mon.registerextvar("system.tests.t6", nil, getvar)
    u.assert_table(t)
    u.assert_equal("system.tests.t6", mon.vars.system.tests.t6)

    t = mon.registerextvar("system.tests.", nil, getvar)
    u.assert_table(t)
    u.assert_equal("system.tests.t7", mon.vars.system.tests.t7)
end

function t:test_regextvar_varlist()

    local function getvar(path, varname) return path..(varname or "") end

    local t = mon.registerextvar("system.tests2.", nil, getvar, {"t1", "t2", "t3"})
    u.assert_table(t)
    u.assert_equal(t, mon.vars.system.tests2)
    local r = {}
    for k, v in pairs(mon.vars.system.tests2) do r[k] = v end
    local c = {t1 = "system.tests2.t1", t2 = "system.tests2.t2", t3 = "system.tests2.t3"}
    u.assert_clone_tables(c, r)

    local called
    t = mon.registerextvar("system.tests3.", nil, getvar, function(path) called = path return {"t1", "t2", "t3"} end)
    u.assert_table(t)
    u.assert_equal(t, mon.vars.system.tests3)
    for k, v in pairs(mon.vars.system.tests3) do r[k] = v end
    c = {t1 = "system.tests3.t1", t2 = "system.tests3.t2", t3 = "system.tests3.t3"}
    u.assert_clone_tables(c, r)
    u.assert_equal("system.tests3.", called)
end

function t:test_regextvar_setvar()
    local r
    local function setvar(path, var, val) r = {path, var, val} end

    local t = mon.registerextvar("system.tests21.t1", nil, nil, nil, setvar)

    r = nil
    mon.vars.system.tests21.t2 = 42
    u.assert_nil(r)

    r = nil
    mon.vars.system.tests21.t1 = 42
    u.assert_clone_tables({"system.tests21.", "t1", 42}, r)

    r = nil
    mon.vars.system.tests21.t1 = "42"
    u.assert_clone_tables({"system.tests21.", "t1", "42"}, r)
end

function t:test_regextvar_setvargroup()
    local r
    local function setvar(path, var, val) r = {path, var, val} end

    local t = mon.registerextvar("system.tests22.", nil, nil, nil, setvar)

    r = nil
    mon.vars.system.tests22.t2 = 42
    u.assert_clone_tables({"system.tests22.", "t2", 42}, r)

    r = nil
    mon.vars.system.tests22.t1 = 42
    u.assert_clone_tables({"system.tests22.", "t1", 42}, r)

    r = nil
    mon.vars.system.tests22.t1 = "42"
    u.assert_clone_tables({"system.tests22.", "t1", "42"}, r)
end



-- test triggers

function t:test_trigger_onchange()
    local t = mon.registerextvar("system.tests4.")
    u.assert_table(t)
    local nvar
    local ngroup
    local function test()
        connect(onchange("system.tests4.t1"), function(v) nvar = v end)
        connect(onchange("system.tests4."), function(v) ngroup = v end)
    end
    u.assert_table(mon.install("test", test, "now"))

    nvar, ngroup = nil, nil
    t.t2 = 1; sched.wait()
    u.assert_equal(nil, nvar)
    u.assert_equal("system.tests4.t2", ngroup)

    nvar, ngroup = nil, nil
    t.t1 = 1; sched.wait();
    u.assert_equal("system.tests4.t1", nvar)
    u.assert_equal("system.tests4.t1", ngroup)

    nvar, ngroup = nil, nil
    t.t1 = 1; sched.wait()
    u.assert_equal(nil, nvar)
    u.assert_equal(nil, ngroup)

    nvar, ngroup = nil, nil
    t.t1 = nil; sched.wait()
    u.assert_equal("system.tests4.t1", nvar)
    u.assert_equal("system.tests4.t1", ngroup)

    nvar, ngroup = nil, nil
    t.t1 = 1; sched.wait()
    u.assert_equal("system.tests4.t1", nvar)
    u.assert_equal("system.tests4.t1", ngroup)
end

function t:test_trigger_onhold1()
    local t = mon.registerextvar("system.tests5.")
    u.assert_table(t)
    local nvar
    local ngroup
    local function test()
        connect(onhold(2, "system.tests5.t1"), function(v) nvar = v or true end)
        connect(onhold(2, "system.tests5."), function(v) ngroup = v or true end)
    end
    u.assert_table(mon.install("test", test, "now"))

    nvar, ngroup = nil, nil
    sched.wait(3)
    u.assert_equal(true, nvar)
    u.assert_equal(true, ngroup)

    nvar, ngroup = nil, nil
    t.t2 = 1; sched.wait(3)
    u.assert_equal(nil, nvar)
    u.assert_equal("system.tests5.t2", ngroup)

    nvar, ngroup = nil, nil
    t.t1 = 1; sched.wait(3)
    u.assert_equal("system.tests5.t1", nvar)
    u.assert_equal("system.tests5.t1", ngroup)

    nvar, ngroup = nil, nil
    t.t1 = 2; sched.wait(1)
    u.assert_equal(nil, nvar)
    u.assert_equal(nil, ngroup)
    t.t1 = 3; sched.wait(1)
    u.assert_equal(nil, nvar)
    u.assert_equal(nil, ngroup)
    t.t1 = 4; sched.wait(1)
    u.assert_equal(nil, nvar)
    u.assert_equal(nil, ngroup)
    t.t1 = 6; sched.wait(3)
    u.assert_equal("system.tests5.t1", nvar)
    u.assert_equal("system.tests5.t1", ngroup)
end

function t:test_trigger_onhold2()
    local t = mon.registerextvar("system.tests5.")
    u.assert_table(t)
    local count = 0
    local ngroup
    local function test()
        connect(onhold(-2, "system.tests5.t3"), function(v) count = count+1 or true end)
    end
    u.assert_table(mon.install("test", test, "now"))

    u.assert_equal(0, count)
    sched.wait(5)
    u.assert_equal(2, count)
    t.t3 = 2; sched.wait(1)
    t.t3 = 3; sched.wait(1)
    t.t3 = 4; sched.wait(1)
    u.assert_equal(2, count)

    u.assert_nil(mon.install("test", "onperiod(-1)", "now"))
end


function t:test_trigger_onperiod()
    local count = 0
    local function test()
        connect(onperiod(2), function(v) count = count+1 end)
    end
    u.assert_table(mon.install("test", test, "now"))

    u.assert_equal(0, count)
    sched.wait(5)
    u.assert_equal(2, count)
end


function t:test_trigger_onconnect()
    local count = 0
    local function test()
        connect(onconnect(), function(v) count = count+1 end)
    end
    u.assert_table(mon.install("test", test, "now"))

    local s = require 'agent.srvcon'
    s.connect()
    u.assert_equal(1, count)
    s.connect()
    u.assert_equal(2, count)
end

if false then
function t:test_trigger_onrecvcmd()
    local c
    local function test()
        connect(onrecvcmd("Command1"), function(cmd, ...) c = {cmd, ...} end)
    end
    u.assert_table(mon.install("test", test, "now"))

    local d = require 'agent.devman'

    local e = {"Command1", "1", "2", "3"}
    local m = {
            otype = "Message",
            path = "@sys.monitoring",
            ticketId = 0,
            type = 2,
            body = {
                otype = "Command",
                name = "Command1",
                args = {
                    otype = "List",
                    elements = { "1", "2", "3" } } } }

     -- fake a new cmd reception
     sched.signal(d.hl, "Message", m)
     sched.wait()
     u.assert_clone_tables(c, e)

     c = nil
     m.body.name="Command2"
     sched.signal(d.hl, "Message", m)
     sched.wait()
     u.assert_nil(c)

end
end

--onthreshold(threshold, var, edge)
function t:test_trigger_onthreshold1()
    local t = mon.registerextvar("system.tests6.")
    u.assert_table(t)
    local c0, c1, c2
    local function test()
        connect(onthreshold(42, "system.tests6.t1", "down"), function() c0 = true  end)
        connect(onthreshold(42, "system.tests6.t1", "up"), function() c1 = true end)
        connect(onthreshold(42, "system.tests6.t1"), function() c2 = true end)
    end
    u.assert_table(mon.install("test", test, "now"))

    c0, c1, c2 = nil, nil, nil
    t.t1 = 10
    t.t1 = 40
    t.t1 = 41
    sched.wait()
    u.assert_nil(c0)
    u.assert_nil(c1)
    u.assert_nil(c2)

    c0, c1, c2 = nil, nil, nil
    t.t1 = 42
    sched.wait()
    u.assert_nil(c0)
    u.assert_true(c1)
    u.assert_true(c2)

    c0, c1, c2 = nil, nil, nil
    t.t1 = 44
    t.t1 = 3215
    t.t1 = 42
    sched.wait()
    u.assert_nil(c0)
    u.assert_nil(c1)
    u.assert_nil(c2)

    c0, c1, c2 = nil, nil, nil
    t.t1 = 41
    sched.wait()
    u.assert_true(c0)
    u.assert_nil(c1)
    u.assert_true(c2)
end

function t:test_trigger_onthreshold2()
    local t = mon.registerextvar("system.tests6.")
    u.assert_table(t)
    local c0, c1, c2
    local function test()
        connect(onthreshold(-42, "system.tests6.t2", "down"), function() c0 = true  end)
        connect(onthreshold(-42, "system.tests6.t2", "up"), function() c1 = true end)
        connect(onthreshold(-42, "system.tests6.t2"), function() c2 = true end)
    end
    u.assert_table(mon.install("test", test, "now"))

    c0, c1, c2 = nil, nil, nil
    t.t2 = -42
    sched.wait()
    u.assert_nil(c0)
    u.assert_nil(c1)
    u.assert_nil(c2)

    c0, c1, c2 = nil, nil, nil
    t.t2 = -43
    sched.wait()
    u.assert_true(c0)
    u.assert_nil(c1)
    u.assert_true(c2)

    c0, c1, c2 = nil, nil, nil
    t.t2 = -44
    t.t2 = -3215
    t.t2 = -43
    sched.wait()
    u.assert_nil(c0)
    u.assert_nil(c1)
    u.assert_nil(c2)

    c0, c1, c2 = nil, nil, nil
    t.t2 = -42
    sched.wait()
    u.assert_nil(c0)
    u.assert_true(c1)
    u.assert_true(c2)


    c0, c1, c2 = nil, nil, nil
    t.t2 = 45
    sched.wait()
    u.assert_nil(c0)
    u.assert_nil(c1)
    u.assert_nil(c2)
end


--ondeadband(deadband, var)
function t:test_trigger_ondeadband()
    local t = mon.registerextvar("system.tests6.")
    u.assert_table(t)
    local c
    local function test()
        connect(ondeadband(5, "system.tests6.t3", "down"), function() c = true  end)
    end
    u.assert_table(mon.install("test", test, "now"))

    c = nil
    t.t3 = 1
    t.t3 = 2
    t.t3 = 4
    t.t3 = -4
    t.t3 = 2
    sched.wait()
    u.assert_nil(c)

    c = nil
    t.t3 = 6
    sched.wait()
    u.assert_true(c)

    c = nil
    t.t3 = 145
    sched.wait()
    u.assert_true(c)

    c = nil
    t.t3 = -69
    sched.wait()
    u.assert_true(c)

    c = nil
    t.t3 = -145
    sched.wait()
    u.assert_true(c)

    c = nil
    t.t3 = -141
    t.t3 = -149
    t.t3 = -145
    t.t3 = -141
    sched.wait()
    u.assert_nil(c)
end