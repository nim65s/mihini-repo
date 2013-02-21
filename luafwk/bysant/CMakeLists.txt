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
project(BYSANTLUA)

include_directories(${LIBBYSANTPROTOCOL_SOURCE_DIR})
include_directories(${COMMON_SOURCE_DIR})
include_directories(../luafwk/linux/liblua)

add_library(bysant_sharedlib SHARED bysant_core_serialize.c bysant_core_deserialize.c bysant_core_common.c)
target_link_libraries(bysant_sharedlib bysant_lib)

add_lua_library(bysant_awtda DESTINATION bysant awtda.lua)

add_lua_library(bysant_core bysant_core_serialize.c bysant_core_deserialize.c bysant_core_common.c)
target_link_libraries(bysant_core bysant_lib)
set_target_properties(bysant_core PROPERTIES OUTPUT_NAME bysant)
