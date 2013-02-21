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

project(racon)

include_directories(${YAJL_SOURCE_DIR})
include_directories(${YAJL_SOURCE_DIR}/include)
include_directories(${YAJL_SOURCE_DIR}/api)
include_directories(${COMMON_SOURCE_DIR})
include_directories(${LIBHESSIANPROTOCOL_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/..)

add_library(Swi_DSet SHARED swi_dset.c)
add_public_header(Swi_DSet swi_dset.h)
target_link_libraries(Swi_DSet pointerlist)

add_library(Emp SHARED emp.c)
target_link_libraries(Emp Swi_DSet pthread)

add_unit_test(dset_test dset_test.c RUNTIME_DEPENDENCIES Swi_Log Swi_DSet)
add_unit_test(emp_test emp_test.c TEST_DEPENDENCY emp_server RUNTIME_DEPENDENCIES Swi_Log Emp pthread yajl)
