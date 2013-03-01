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

# CMakeLists for the lua linux version
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(LIB_EXTVARS)


INCLUDE_DIRECTORIES(
    ${LIB_MIHINI_COMMON_SOURCE_DIR}
    ${LIB_EXTVARS_COMMON_SOURCE_DIR}
    ${LIB_MIHINI_LUASIGNAL_SOURCE_DIR}
)


ADD_LIBRARY(lib_extvars SHARED EXCLUDE_FROM_ALL extvars.c)
TARGET_LINK_LIBRARIES(lib_extvars lib_pointerlist lib_luasignal pthread)
SET_TARGET_PROPERTIES(lib_extvars PROPERTIES OUTPUT_NAME extvars)

ADD_SUBDIRECTORY (treehdlsample)
