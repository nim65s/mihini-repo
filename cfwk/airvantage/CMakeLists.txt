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

project (airvantage)

include_directories (${LUA_SOURCE_DIR}/liblua)
include_directories(${YAJL_SOURCE_DIR})
include_directories(${YAJL_SOURCE_DIR}/include)
include_directories(${YAJL_SOURCE_DIR}/api)
include_directories(${COMMON_SOURCE_DIR})
include_directories(${racon_SOURCE_DIR})
include_directories(${LIBHESSIANPROTOCOL_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/..)

set(SRC_SWIAV swi_airvantage.c)

add_library(Swi_AirVantage SHARED ${SRC_SWIAV})
add_public_header(Swi_AirVantage swi_airvantage.h)
target_link_libraries(Swi_AirVantage Emp yajl Swi_Log)

add_unit_test(av_test av_test.c RUNTIME_DEPENDENCIES Swi_AirVantage Swi_Log luavm)

