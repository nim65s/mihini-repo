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

require "strict"
local sched = require "sched"
local rpc = require "rpc"

global 'gx_addr'
gx_addr = gx_addr or "192.168.13.31"
print(string.format("GX ip address: '%s'", gx_addr))

global 't_folder'
t_folder = t_folder or "/home/gilles/eclipse/workspace/platform-embedded/build.default/runtime"
print(string.format("tests: '%s'", t_folder))

os.execute("scp "..t_folder.."/lua/tests/* root@"..gx_addr..":/root/aleos/usr/readyagent/lua/tests")
os.execute("scp "..t_folder.."/resources/table1.map "..t_folder.."/resources/table2.map "..t_folder.."/resources/testramstore.map root@"..gx_addr..":/root/aleos/usr/readyagent/resources")

tscript = [[
    require 'tests.luatobin'
	require 'tests.persist'
	require 'tests.qdbm'
	require 'tests.rpc'
	require 'tests.sched'
	--require 'tests.socket'
	require 'tests.posixsignal'
	require 'tests.modbusserializer'
	
	require 'tests.config'
	require 'tests.mediation'
	--require 'tests.monitoring'
	require 'tests.hessian'
	require 'tests.stagedb'
	require 'tests.treemgr'
	--require 'tests.bysant'
	--require 'tests.portal'
	require 'tests.asset_tree'
	
	agent.system.reboot = print
	
	function testrun()
		local utest = require 'unittest';
		utest.run()
		return utest.getStats()
 	end	
]]

testres = nil
function autotest()
	local client, err = rpc.newclient(gx_addr)
	print(string.format("Create RPC client: '%s'", not client and "ERROR" or "OK"))

	local testinstall
	testinstall, err = client:newexec(tscript)
	print(string.format("Remote send script: '%s'", not testinstall and "ERROR" or "OK"))
	
	testinstall()
	testres = client:call("testrun")
end
