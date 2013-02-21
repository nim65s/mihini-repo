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

project (AGENT)

include_directories (${LUA_SOURCE_DIR}/lua)
include_directories (executable)
include_directories (${COMMON_SOURCE_DIR})

add_executable (agent executable/agent.c)

target_link_libraries (agent luavm pthread)  #link to pthread should not be necessary here but prevent a segfault when using uClibc (to be removed when NPTL is used)

add_lua_library(versions DESTINATION agent executable/version.c executable/sysversion.c)

add_subdirectory(agent)

add_custom_command(TARGET agent POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/system/start.sh ${CMAKE_INSTALL_PREFIX}/start.sh
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/system/GPRS ${CMAKE_INSTALL_PREFIX}/bin/GPRS
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/system/ETH ${CMAKE_INSTALL_PREFIX}/bin/ETH
)
