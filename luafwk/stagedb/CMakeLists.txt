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

project(STAGEDB_LUA)

include_directories(${LIBBYSANTPROTOCOL_SOURCE_DIR})
include_directories(${BYSANTLUA_SOURCE_DIR})
include_directories(${COMMON_SOURCE_DIR})
include_directories(../../luafwk/linux/liblua)

add_lua_library(stagedb stagedb_core.c stagedb.lua)
target_link_libraries(stagedb stagedb_lib bysant_lib bysant_sharedlib)
