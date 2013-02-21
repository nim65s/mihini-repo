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

add_lua_library(embeddedteststools DESTINATION tests/tools EXCLUDE_FROM_ALL
  client.lua
  libtests.lua
  logmanager.lua
  webservicesaccess.lua
  ../../../luafwk/luasocket/test/sockettestsvr.lua
  systemtest.lua
)

ADD_CUSTOM_TARGET(customclientagent_install
        COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/specific_defaultconfig.lua ${CMAKE_LUA_LIBRARY_OUTPUT_DIRECTORY}/agent/defaultconfig.lua        
        )
add_lua_library(scriptmigrationhelperlua DESTINATION agent EXCLUDE_FROM_ALL
 migration.lua
)
add_lua_library(testsmigrationhelperlua DESTINATION tests/tools EXCLUDE_FROM_ALL)
add_dependencies(testsmigrationhelperlua scriptmigrationhelperlua customclientagent_install)

add_lua_library(testsmigrationwithout DESTINATION tests/tools EXCLUDE_FROM_ALL)
add_dependencies(testsmigrationwithout customclientagent_install)


include_directories(${COMMON_SOURCE_DIR})
include_directories (../tests/scripts/tools)
add_lua_library(migration DESTINATION agent EXCLUDE_FROM_ALL
  migration.c
)
add_lua_library(testsmigrationhelperc DESTINATION tests/tools EXCLUDE_FROM_ALL)
add_dependencies(testsmigrationhelperc migration customclientagent_install)


include_directories (../../../luafwk/lua)


