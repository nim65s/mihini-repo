-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Julien Desgats     for Sierra Wireless - initial API and implementation
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

--local 
asset = nil
local airvantage = require 'airvantage'
local u     = require 'unittest'
local c     = require 'agent.config'
local http  = require 'socket.http'
local niltoken = require 'niltoken'
local deserialize = require 'hessian.deserialize'
local upath = require 'utils.path'
--local 
dm      = require 'agent.asscon.datamanager'
local t = u.newtestsuite("airvantage")

-- this test changes the server URL to the fake test server and resets the old one back
local oldurl = nil
local TEST_URL = "http://localhost:8888/device/com"

local ASSET_NAME = 'asset'

local function clear_tables()
    for table_id, t in pairs(dm.tables) do
        -- break the source/destination link to avoid errors (ok as we close ALL tables)
        t.src_table = nil
        u.assert(dm.close_table(asset.id, table_id))
    end
    u.assert_nil(next(dm.tables))
end

local function last_sent_value()
    local raw = http.request("http://localhost:8888/lastvalue")
    local envelope = deserialize.value(raw)
    if not niltoken(envelope) then return nil end
    local payload = envelope.payload
    if payload and #payload>1 then
        local bodies = { }
        for i, v in ipairs(payload) do
            bodies[i] = payload[i].body
        end
        return bodies
    else return payload[1].Body end
end

-- builds a full list of path (relative to the asset) --> value.
-- Contrary to last_sent_value, this function supports multiple payload
-- messages in a single envelope.
local function last_sent_data()
    local raw = http.request("http://localhost:8888/lastvalue")
    local envelope = deserialize.value(raw)
    if not niltoken(envelope) then return nil end
    local payload = envelope.payload
    local r = { }
    for _, msg in ipairs(payload) do
        local _, path = upath.split(msg.Path, 1)
        local body = msg.Body
        for k, v in pairs(body) do
            r[upath.concat(path, k)] = v
        end
    end
    return r
end

function t :setup()
    -- Setup for local test server, disabled by default
	if false and agent.config.get 'server.transportprotocol' ~= 'http' then
	    agent.config.set('server.transportprotocol', 'http')
	    print "'\n\nChanged config, agent must be restarted\n\n"
	    os.exit(-1)
	end
    if not asset then
        local airvantage = require 'airvantage'
        u.assert(airvantage.init())
        asset = airvantage.newasset (ASSET_NAME)
        u.assert(asset :start())
        dm.new_policy('manualpolicy', {'manual'})
    end
    oldurl = agent.config.get('server.url')
    agent.config.set('server.url', TEST_URL)
end

function t :teardown()
    clear_tables()
	if asset then u.assert(asset :close()) end
	agent.config.set('server.url', oldurl)
end

function t :test_file_retrieve()
    local path = 'persistedlocation'
    local tbl = u.assert(asset :newtable (path, { 'x', 'y', 'timestamp'}, 'file'))
    tbl :pushrow{ x=1, y=2, timestamp=os.time() }
    -- qu'est-ce qu'on fait d'une table flushee et dereferencee??
    local n = dm.tables[tbl.id].sdb:state().nrows
    u.assert(n>=1)
    u.assert(dm.close_table(ASSET_NAME, tbl.id))
    tbl = u.assert(asset :newtable (path, { 'x', 'y', 'timestamp'}, 'file'))
    u.assert( n == dm.tables[tbl.id].sdb:state().nrows)
    clear_tables()
end 

function t :test_ram_dont_retrieve()
    local path = 'volatilelocation'
    local tbl = u.assert(asset :newtable (path, { 'x', 'y', 'timestamp'}))
    tbl :pushrow{ x=1, y=2, timestamp=os.time() }
    u.assert( 1 == dm.tables[tbl.id].sdb:state().nrows)
    u.assert(dm.close_table(ASSET_NAME, tbl.id))
    tbl = u.assert(asset :newtable (path, { 'x', 'y', 'timestamp'}))
    u.assert( 0 == dm.tables[tbl.id].sdb:state().nrows)
    clear_tables()
end

function t :test_empty_table()
    local tbl = u.assert(asset :newtable ('testtable', { 'x', 'y', 'timestamp'}))
    tbl :send()
    u.assert( 0 == dm.tables[tbl.id].sdb:state().nrows)
    tbl :pushrow{ x=1, y=1, timestamp=os.time()}
    u.assert( 1 == dm.tables[tbl.id].sdb:state().nrows)
    tbl :send()
    u.assert( 0 == dm.tables[tbl.id].sdb:state().nrows)
end

function t :test_unstructured()
    for i=1, 100 do
       u.assert(asset :pushdata('positions', {x=i, y=10*i}))
    end
    u.assert(airvantage.triggerpolicy())
end

function t :test_multi_segment_keys()
    u.assert(asset :pushdata('a',{['b.c']={d=123}, e=234, f={g=345}}, 'default'))
    airvantage.triggerPolicy('default')
    local x = u.assert(last_sent_data())
    u.assert_equal(x['a.b.c.d'][1], 123)
    u.assert_equal(x['a.e'][1], 234)
    u.assert_equal(x['a.f.g'][1], 345)
end

function t :test_parallel_table()
    local tbl = u.assert(asset :newtable ('somepath', { 'x', 'y', 'timestamp'}))
    local N = 10
    local nsuccesses = 0
    local function f(n, w)
        log('PORTAL-TEST', 'INFO', "starting thread %d", n)
        for i=10, 1000, 10 do
            u.assert(tbl :pushrow{ x=i+n, y=-i-n, timestamp=os.time()})
            if w then sched.wait() end
        end
        u.assert(tbl :send())
        nsuccesses = nsuccesses+1
        log('PORTAL-TEST', 'INFO', "success #%d", nsuccesses)
        if nsuccesses==N then 
            sched.signal('test_parallel_table', 'done')
        end
        log('PORTAL-TEST', 'INFO', "finished thread %d", n)
    end
    for i=1, N do
        sched.run(f, i, i%2==0)
    end
    sched.wait('test_parallel_table', 'done')
    clear_tables()
end

function t :test_autoflush()
    local tbl = u.assert(asset :newtable ('autoflushed', { 'x', 'y', 'timestamp'}))
    local N = 5
    u.assert(tbl :setmaxrows(N))
    u.assert_equal(dm.tables[tbl.id].maxrows, N)
    for i=1, 3*N do
        u.assert(tbl :pushrow{ x=1, y=2, timestamp=os.time() })
        local nrows = dm.tables[tbl.id].sdb:state().nrows
        if i%N==0 then wait(5) end -- Leave time for the server to answer the flush
        u.assert_equal(nrows, i % N, "Data flush likely not acknowledged by server")
    end
    clear_tables()
end

function t :test_conso_basic()
    local tbl = u.assert(asset:newTable('mytable_basic', { 'x', 'y', 'timestamp'}, 'ram', 'never'))
    local conso = u.assert(tbl:newConsolidation('myconso_basic', {x='mean', y='mean', timestamp='median'}, 'ram'))
    -- cannot set 2 consolidation tables
    u.assert_nil(tbl:newConsolidation('conso2', {x='mean', y='mean', timestamp='median'}, 'ram'))
    
    -- for send, data must not be consolidated
    tbl :pushRow{ x=1, y=3, timestamp=5 }
    tbl :pushRow{ x=2, y=6, timestamp=10 }
    tbl :pushRow{ x=3, y=3, timestamp=15 }
    u.assert(tbl :send())
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(0, dm.tables[conso.id].sdb:state().nrows)
    
    tbl :pushRow{ x=1, y=3, timestamp=5 }
    tbl :pushRow{ x=2, y=6, timestamp=10 }
    tbl :pushRow{ x=3, y=3, timestamp=15 }
    u.assert(tbl :consolidate())
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(1, dm.tables[conso.id].sdb:state().nrows)
    clear_tables()
end

function t :test_conso_maxrow()
    local tbl = u.assert(asset:newTable('mytable_max', { 'x', 'y', 'timestamp'}, 'ram', 'never'))
    local conso = u.assert(tbl:newConsolidation('myconso_max', {x='mean', y='mean', timestamp='median'}, 'ram'))
    tbl:setMaxRows(3)
    conso:setMaxRows(2)
    
    last_sent_value() -- clear last sent value
    tbl :pushRow{ x=1, y=3, timestamp=5 }
    tbl :pushRow{ x=2, y=6, timestamp=10 }
    tbl :pushRow{ x=3, y=3, timestamp=15 }
    
    -- tbl has been consolidated
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(1, dm.tables[conso.id].sdb:state().nrows)
    u.assert_nil(last_sent_value())
    
    tbl :pushRow{ x=4, y=4, timestamp=20 }
    tbl :pushRow{ x=5, y=4, timestamp=25 }
    tbl :pushRow{ x=6, y=4, timestamp=30 }
    
    -- tbl has been consolidated and conso has been sent to server
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(0, dm.tables[conso.id].sdb:state().nrows)
    u.assert_clone_tables({ x={2,5}, y={4,4}, timestamp={10,25}}, last_sent_value())
    clear_tables()
end

function t :test_conso_policy1()
    local tbl = u.assert(asset:newTable('mytable_pol1', { 'x', 'y', 'timestamp'}, 'ram', 'never'))
    local conso = u.assert(tbl:newConsolidation('myconso_pol1', {x='mean', y='mean', timestamp='median'}, 'ram', 'default', 'manualpolicy'))
    
    tbl :pushRow{ x=1, y=3, timestamp=5 }
    tbl :pushRow{ x=2, y=6, timestamp=10 }
    tbl :pushRow{ x=3, y=3, timestamp=15 }
    
    airvantage.triggerPolicy('default')
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(1, dm.tables[conso.id].sdb:state().nrows)
    airvantage.triggerPolicy('manualpolicy')
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(0, dm.tables[conso.id].sdb:state().nrows)
    clear_tables()
end

function t :test_conso_policy_conflict()
    local tbl = u.assert(asset:newTable('mytable_pol3', { 'x', 'y', 'timestamp'}, 'ram', 'default'))
    u.assert_nil(tbl:newConsolidation('myconso_pol3', {x='mean', y='mean', timestamp='median'}, 'ram', 'default'))
    clear_tables()
end

-- This test is really intrusive and simulates concurrency fetween policies
function t :test_concurrent_policies()
    local function createtables(suffix, consoPolicy, sendPolicy)
        local tbl = u.assert(asset:newTable('mytable_'..suffix, { 'x', 'y', 'timestamp'}, 'ram', 'never'))
        local conso = u.assert(tbl:newConsolidation('myconso_'..suffix, {x='mean', y='mean', timestamp='median'}, 'ram', consoPolicy, sendPolicy))
        tbl :pushRow{ x=1, y=3, timestamp=5 }
        tbl :pushRow{ x=2, y=6, timestamp=10 }
        tbl :pushRow{ x=3, y=3, timestamp=15 }
        return tbl, conso
    end
    local tbl, conso, now
    
    -- both tables are in the same policy, test that data is consolidated before beeing sent
    tbl, conso = createtables('same', 'default', 'default')
    airvantage.triggerPolicy('default')
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(0, dm.tables[conso.id].sdb:state().nrows)
    u.assert_clone_tables({ x={2}, y={4}, timestamp={10}}, last_sent_value())
    clear_tables()
    
    -- consolidation and send policies are different but triggered at the same time
    -- 1st case: consolidation is triggered before send
    tbl, conso = createtables('consosend', 'default', 'manualpolicy')
    now = os.time()
    dm.policies.default.nextevent, dm.policies.manualpolicy.nextevent = now, now
    airvantage.triggerPolicy('default')
    airvantage.triggerPolicy('manualpolicy')
    
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(0, dm.tables[conso.id].sdb:state().nrows)
    u.assert_clone_tables({ x={2}, y={4}, timestamp={10}}, last_sent_value())
    clear_tables()
    
    -- 2nd case: send is triggered before consolidation but datamgr sould still wait 
    -- for consolidation before sending data
    tbl, conso = createtables('sendconso', 'default', 'manualpolicy')
    now = os.time()
    dm.policies.default.nextevent, dm.policies.manualpolicy.nextevent = now, now
    local sendtask = sched.run(airvantage.triggerPolicy, 'manualpolicy')
    sched.wait() -- let the sending task start before running the consolidation one
    airvantage.triggerPolicy('default')
    u.assert_not_equal('timeout', sched.wait(sendtask, 'die', 5), 'deadlock between conso and send')
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(0, dm.tables[conso.id].sdb:state().nrows)
    u.assert_clone_tables({ x={2}, y={4}, timestamp={10}}, last_sent_value())
    clear_tables()
    
    -- consolidation and send policies are different and not triggered at same time
    last_sent_value() -- clear value
    tbl, conso = createtables('notsame', 'default', 'manualpolicy')
    now = os.time()
    -- consolidation will be triggered 2 seconds after send
    dm.policies.default.nextevent, dm.policies.manualpolicy.nextevent = now + 2, now
    u.assert_not_equal('timeout', sched.wait(sched.run(airvantage.triggerPolicy, 'manualpolicy'), 'die', 5), 
       'send should not have waited for consolidation')
    sched.wait(2)
    airvantage.triggerPolicy('default')
    
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    u.assert_equal(1, dm.tables[conso.id].sdb:state().nrows, 'data should be still in local table')
    u.assert_nil(last_sent_value(), 'data should be still in local table')
    clear_tables()
end

function t :test_reset()
    local tbl = u.assert(asset :newtable ('reseted', { 'x', 'y', 'timestamp'}))
    tbl :pushRow{ x=1, y=3, timestamp=5 }
    u.assert_equal(1, dm.tables[tbl.id].sdb:state().nrows)
    tbl :reset()
    u.assert_equal(0, dm.tables[tbl.id].sdb:state().nrows)
    clear_tables()
end

function t :test_purge_reuse()
    -- test that when purge is set the table is different
    local tbl = u.assert(asset :newtable ('recreated', { 'x', 'y', 'timestamp'}))
    local firsthandle = dm.tables[tbl.id].sdb
    tbl = u.assert(asset :newtable ('recreated', { 'x', 'y', 'timestamp'}, nil, nil, true))
    local secondhandle = dm.tables[tbl.id].sdb
    u.assert_not_equal(secondhandle, firsthandle)
    
    -- when purge is not set, table should be reused
    tbl = u.assert(asset :newtable ('recreated', { 'x', 'y', 'timestamp'}))
    local thirdhandle = dm.tables[tbl.id].sdb
    u.assert_equal(secondhandle, thirdhandle)

    clear_tables()
end

function t :test_purge_reuse_consolidation()
    -- test that when purge is set the table is different
    local src = u.assert(asset :newtable ('src-purge', { 'x', 'y', 'timestamp' }, nil, 'never'))
    local dst = u.assert(src :newconsolidation('dst-purge', { x='mean', y='mean', timestamp='mean'}))
    local firstsrc, firstdst = dm.tables[src.id].sdb, dm.tables[dst.id].sdb
    -- TODO: also try with different column structures
    u.assert_nil(asset :newtable('dst-purge', {'x', 'y', 'timestamp'}, nil, nil, true)) -- should fail as 'dst-purge' table already exists
    
    local src = u.assert(asset :newtable ('src-purge', { 'x', 'y', 'timestamp'}, nil, 'never', true))
    local dst = u.assert(src :newconsolidation('dst-purge', { x='mean', y='mean', timestamp='mean'}, nil, nil, nil, true))
    local secondsrc, seconddst = dm.tables[src.id].sdb, dm.tables[dst.id].sdb
    u.assert_not_equal(firstsrc, secondsrc)
    u.assert_not_equal(firstdst, seconddst)
    
    local src = u.assert(asset :newtable ('src-purge', { 'x', 'y', 'timestamp'}, nil, 'never'))
    u.assert_nil(src :newconsolidation('dst-purge', { x='mean', y='mean'})) -- cannot reuse as columns are different
    local dst = u.assert(src :newconsolidation('dst-purge', { x='mean', y='mean', timestamp='mean'}))
    local thirdsrc, thirddst = dm.tables[src.id].sdb, dm.tables[dst.id].sdb
    u.assert_equal(thirdsrc, secondsrc)
    u.assert_equal(thirddst, seconddst)
    
    local other = u.assert(asset :newtable ('other-purge', { 'x', 'y', 'timestamp'}, nil, 'never'))
    -- no matter the purge argument, some cases leads to errors
    u.assert_nil(other :newconsolidation('dst-purge', {x='min', y='max', timestamp='mean'}, nil, nil, nil, true)) -- ID already used by anoter destination
    u.assert_nil(other :newconsolidation('dst-purge', {x='min', y='max', timestamp='mean'}, nil, nil, nil, false))
    u.assert_nil(dst :newconsolidation('other-purge', { x='mean', y='mean', timestamp='mean'}, nil, nil, nil, true)) -- ID already used by anoter table
    u.assert_nil(dst :newconsolidation('other-purge', { x='mean', y='mean', timestamp='mean'}, nil, nil, nil, false))
    
    clear_tables()
end

function t :test_nopath()
    u.assert(asset :pushdata('positions', {x=1, y=2}))
    u.assert(asset :pushdata({alive=true}))
    u.assert(asset :pushdata('asset_relative_path', 42))
    u.assert(asset :pushdata{meaning_of_life=42})
    u.assert_error(function() asset :pushdata(42) end)
    u.assert_error(function() asset :pushdata('neither_key_nor_path') end)
end

-- Subscribe 2 times: if unregistration worked correctly, the 2nd registration
-- must be accepted.
function t :test_unregister()
	local a = u.assert(airvantage.newasset('test_unregister_asset'))
	u.assert (a :start())
	u.assert (a :close())
	a = u.assert(airvantage.newasset('test_unregister_asset'))
	u.assert (a :start())
	u.assert (a :close())
end

-- tests to do:
-- clean fail on improper retrieval?
-- check that no data is sent twice [need server-side support]

return t