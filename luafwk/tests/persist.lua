-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Gilles Cannenterre for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local target = require 'persist'
local u = require 'unittest'
local _G = _G

local t = u.newtestsuite("persist")

local cb, val, nt, last

function t:setup()
    cb = target.newcbuffer("testCBuffer", 128)
    nt = target.table.new("testNewtable")
end

function t:test_cbuffer_enque()
    cb:clear()
    val = cb:read()
    u.assert_equal(val, "")

    for i=1, 64 do
       val = cb:enque(i)
       u.assert_gte(0, val)
    end
end

function t:test_cbuffer_read()
    cb:clear()
    val = cb:read()
    u.assert_equal(val, "")

    for i=1, 64 do
       val = cb:enque(i)
       u.assert_gte(0, val)
    end

    val = cb:read()
    u.assert_not_nil(val)
    u.assert_gte(0, #val)

    for i=1, 64 do
       val = cb:read(i)
       u.assert_not_nil(val)
       u.assert_gte(0, #val)
    end

    val = cb:read(nil, true)
    u.assert_table(val)
    for i=1, #val-1 do
       u.assert_equal(tonumber(val[i]), tonumber(val[i+1]) - 1)
    end

    for i=1, 64 do
       val = cb:read(i, true)
       u.assert_table(val)
       for j=1, #val-1 do
           u.assert_equal(tonumber(val[j]), tonumber(val[j+1]) - 1)
       end
    end
end

function t:test_cbuffer_deque()
    cb:clear()
    val = cb:read()
    u.assert_equal(val, "")

    for i=1, 64 do
       val = cb:enque(i)
       u.assert_gte(0, val)
    end

    last = val
    for i=1, 64 do
       val = cb:deque(1)
       u.assert_lte(last, val)
       last = val
    end
end

function t:test_cbuffer_enque_deque()
    cb:clear()
    val = cb:read()
    u.assert_equal(val, "")
    local tab = {"les poissons d'avril", "les moutons de panurge", "l'ours", "le grizzly", "mimi cracra", "", "la panth�re rose", "le dindon de la farce", "la vie en rose", "bioman", "r�cr�ation"}
    for i=1, 30 do
       cb:enque("what a beautiful value:"..i)
    end
    cb:enque(tab)

    val = cb:deque()
    u.assert_equal(0, cb.states[3])
end

function t:test_newtable()
    target.table.empty(nt)
    for i=1,256 do
        nt["key"..i] = "value"..i
    end

    for i=1,256 do
       local val = nt["key"..i]
       u.assert_equal("value"..i, val)
    end

    for i=1,256 do
        nt["key"..i] = "value"..(2*i)
    end

    for i=1,256 do
       local val = nt["key"..i]
       u.assert_equal("value"..(2*i), val)
    end

    for i=1,256 do
        nt["key"..i] = nil
    end

    for i=1,256 do
       local val = nt["key"..i]
       u.assert_nil(val)
    end
end

function t:test_persit_store()
    local obj = {function () return "titi" end, 1 , "string test", nil, true}
    target.save("test_persit_store", obj)

    local val = target.load("test_persit_store")
    u.assert_table(val)
    u.assert_function(val[1])
    u.assert_equal("titi", val[1]())
    u.assert_equal(1, val[2])
    u.assert_equal("string test", val[3])
    u.assert_nil(val[4])
    u.assert_equal(true, val[5])

    target.save("test_persit_store", nil)
    val = target.load("test_persit_store")
    u.assert_nil(val)
end

function t:teardown()
    cb:clear()
    cb = nil
    target.table.empty(nt)
    nt = nil
end
