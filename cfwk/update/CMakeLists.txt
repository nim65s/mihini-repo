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

project (update)

include_directories (${LUA_SOURCE_DIR}/liblua)
include_directories(${racon_SOURCE_DIR})
include_directories(${COMMON_SOURCE_DIR})
include_directories(${YAJL_SOURCE_DIR})
include_directories(${YAJL_SOURCE_DIR}/include)
include_directories(${YAJL_SOURCE_DIR}/api)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/..)

add_library(Swi_Update SHARED swi_update.c)
add_public_header(Swi_Update swi_update.h)
target_link_libraries(Swi_Update Emp yajl Swi_Log)

add_unit_test(updatetest update_test.c TEST_DEPENDENCY messaging_stubs RUNTIME_DEPENDENCIES Swi_Update Swi_Log luavm)
