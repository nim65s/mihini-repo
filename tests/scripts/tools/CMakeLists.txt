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

ADD_LUA_LIBRARY(embeddedteststools DESTINATION tests/tools EXCLUDE_FROM_ALL
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
ADD_LUA_LIBRARY(scriptmigrationhelperlua DESTINATION agent EXCLUDE_FROM_ALL
 migration.lua
)
ADD_LUA_LIBRARY(testsmigrationhelperlua DESTINATION tests/tools EXCLUDE_FROM_ALL)
ADD_DEPENDENCIES(testsmigrationhelperlua scriptmigrationhelperlua customclientagent_install)

ADD_LUA_LIBRARY(testsmigrationwithout DESTINATION tests/tools EXCLUDE_FROM_ALL)
ADD_DEPENDENCIES(testsmigrationwithout customclientagent_install)


INCLUDE_DIRECTORIES(${LIB_MIHINI_COMMON_SOURCE_DIR})
INCLUDE_DIRECTORIES (../tests/scripts/tools)
ADD_LUA_LIBRARY(migration DESTINATION agent EXCLUDE_FROM_ALL
  migration.c
)
ADD_LUA_LIBRARY(testsmigrationhelperc DESTINATION tests/tools EXCLUDE_FROM_ALL)
ADD_DEPENDENCIES(testsmigrationhelperc migration customclientagent_install)


INCLUDE_DIRECTORIES (../../../luafwk/lua)


