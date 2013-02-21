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
include(cmake/add_lua_library.cmake)
include(cmake/add_public_header.cmake)
include(cmake/add_unit_test.cmake)
project (EMBEDDED)

add_definitions(-Wall)
set(CMAKE_INSTALL_PREFIX ${EMBEDDED_BINARY_DIR}/runtime)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${EMBEDDED_BINARY_DIR}/static-libs)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${EMBEDDED_BINARY_DIR}/runtime/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${EMBEDDED_BINARY_DIR}/runtime/lib)
set(CMAKE_LUA_LIBRARY_OUTPUT_DIRECTORY ${EMBEDDED_BINARY_DIR}/runtime/lua)
set(CMAKE_PUBLIC_HEADERS_OUTPUT_DIRECTORY ${EMBEDDED_BINARY_DIR}/runtime/itf)


# remove the lib prefix on unix systems...
set(CMAKE_SHARED_MODULE_PREFIX "")


# Set the git revision if it exists
if(EXISTS "${PROJECT_SOURCE_DIR}/.git/")
    find_package(Git)
    if(GIT_FOUND)
        set(ENV{GIT_DIR} ${PROJECT_SOURCE_DIR}/.git)
        execute_process(COMMAND git rev-parse --short HEAD OUTPUT_VARIABLE GIT_REVISION)
        string(REPLACE "\n" "" GIT_REVISION "${GIT_REVISION}")
        add_definitions(-DGIT_REV=\"${GIT_REVISION}\")
        unset(ENV{GIT_DIR})
    endif(GIT_FOUND)
else(EXISTS "${PROJECT_SOURCE_DIR}/.git/")
    add_definitions(-DGIT_REV=\"Unknown\")
endif(EXISTS "${PROJECT_SOURCE_DIR}/.git/")

add_subdirectory (libs)
add_subdirectory (luafwk)
add_subdirectory (agent)
add_subdirectory (cfwk)
add_subdirectory (tools/appmon_daemon)
add_subdirectory (tools/luasignalcmd)
add_subdirectory (projects)
add_subdirectory (tests)
add_subdirectory (tools/LuaPlatformServer)
add_subdirectory (doc)

if(EXISTS "${PROJECT_SOURCE_DIR}/non-free/CMakeLists.txt")
add_subdirectory (non-free)
endif()



