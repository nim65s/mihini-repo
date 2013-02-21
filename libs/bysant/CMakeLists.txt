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

cmake_minimum_required (VERSION 2.6)
project (LIBBYSANTPROTOCOL)

include_directories(${COMMON_SOURCE_DIR})

set(BYSANT_SRC bysants.c bysantd.c bysant_common.c bysant_class.c ${COMMON_SOURCE_DIR}/awt_endian.c)

add_library(bysant_lib SHARED ${BYSANT_SRC})
target_link_libraries(bysant_lib m)
SET_TARGET_PROPERTIES(bysant_lib PROPERTIES COMPILE_FLAGS -fPIC)

add_library(bysantlib-static EXCLUDE_FROM_ALL STATIC ${BYSANT_SRC})
target_link_libraries(bysantlib-static m)
SET_TARGET_PROPERTIES(bysantlib-static PROPERTIES COMPILE_FLAGS -fPIC)

set(SDB_SRC
  sdb_table.c
  sdb_read.c
  sdb_write.c
  sdb_serialize.c
  sdb_consolidate.c)

add_library(stagedb_lib SHARED ${SDB_SRC})
target_link_libraries(stagedb_lib bysant_lib)

add_library(stagedblib-static EXCLUDE_FROM_ALL STATIC ${SDB_SRC})
target_link_libraries(stagedblib-static bysantlib-static)
