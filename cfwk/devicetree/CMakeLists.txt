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

project (devicetree)

include_directories(${YAJL_SOURCE_DIR})
include_directories(${YAJL_SOURCE_DIR}/include)
include_directories(${YAJL_SOURCE_DIR}/api)
include_directories(${racon_SOURCE_DIR})
include_directories(${COMMON_SOURCE_DIR})
include_directories(${airvantage_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/..)

set(SRC_SWIDEVICETREE swi_devicetree.c)

add_library(Swi_DeviceTree SHARED ${SRC_SWIDEVICETREE})
add_public_header(Swi_DeviceTree swi_devicetree.h)
target_link_libraries(Swi_DeviceTree Emp yajl)

add_unit_test(dt_test dt_test.c RUNTIME_DEPENDENCIES Swi_DeviceTree Swi_Log)
