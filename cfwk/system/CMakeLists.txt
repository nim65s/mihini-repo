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

project (sms)


include_directories(${YAJL_SOURCE_DIR})
include_directories(${YAJL_SOURCE_DIR}/include)
include_directories(${YAJL_SOURCE_DIR}/api)
include_directories(${COMMON_SOURCE_DIR})
include_directories(${racon_SOURCE_DIR})

set(SRC_SWISYSTEM swi_system.c)

add_library(Swi_System SHARED ${SRC_SWISYSTEM})
add_public_header(Swi_System swi_system.h)
target_link_libraries(Swi_System Emp yajl)

if(SHARKS_DEV_BUILD)
  add_unit_test(sys_test sys_test.c TEST_DEPENDENCY system_stubs RUNTIME_DEPENDENCIES Swi_System Swi_Log)
else()
  add_unit_test(sys_test sys_test.c RUNTIME_DEPENDENCIES Swi_System Swi_Log)
endif()
