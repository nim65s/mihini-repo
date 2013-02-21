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

include_directories(${LIB_LINUX_SOURCE_DIR})
include_directories(${COMMON_SOURCE_DIR})

add_lua_library(sched DESTINATION sched
                init.lua 
                timer.lua 
                platform.lua 
                fd.lua
		exec.lua)
                
add_lua_library(posixsignal DESTINATION sched 
                posixsignal/lposixsignal.c)

add_lua_library(exec_core DESTINATION sched 
                exec_core.c)
target_link_libraries(exec_core luasignal pthread)
