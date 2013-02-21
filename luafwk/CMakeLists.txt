#*******************************************************************************
# Copyright (c) 2012 Sierra Wireless and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Sierra Wireless - initial API and implementation
#*******************************************************************************

project (LUA)

include_directories(lua)

add_subdirectory (tests)
add_subdirectory (serialframework)

add_subdirectory (checks)
add_subdirectory (lpack)
add_subdirectory (luatobin)
add_subdirectory (messaging)
add_subdirectory (shell)
add_subdirectory (log)
add_subdirectory (luasocket)
add_subdirectory (ntp)
add_subdirectory (sched)
add_subdirectory (crypto)
add_subdirectory (utils)
add_subdirectory (web)
add_subdirectory (rpc)

add_subdirectory (coxpcall)
add_subdirectory (lfs)
add_subdirectory (loader)
add_subdirectory (lua)
add_subdirectory (serial)
add_subdirectory (luacdb)
add_subdirectory (persist)
add_subdirectory (lua-yajl)

add_lua_library(luafwk_misc 
	daemon.lua lock.lua pipe.lua print.lua
	strict.lua timer.lua unittest.lua niltoken.lua )

add_lua_library(luafwk_linux
                fdwrapper.lua messaginghal.lua posixsignal.lua
)
include_directories(liblua)

add_subdirectory(bysant)
add_subdirectory(stagedb)

add_lua_library(racon
    =/racon/asset/init.lua =racon/asset/tree.lua =racon/common.lua 
    =racon/empparser.lua =racon/init.lua =racon/ipc.lua =racon/table.lua
    =racon/system.lua =racon/devicetree.lua =racon/sms.lua
    system.lua airvantage.lua devicetree.lua sms.lua)

add_lua_library(luadebug
    debugger.lua debugintrospection.lua)
