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
cmake_minimum_required (VERSION 2.6)
project (EXTVARSCOMMON)

set(EXTVARSCOMMON_SRC
    ${EXTVARSCOMMON_SOURCE_DIR}/extvars.c
)


include_directories(
    ${COMMON_SOURCE_DIR}
    ${EXTVARSCOMMON_SOURCE_DIR}
    ${LIB_LINUX_SOURCE_DIR}
)


add_library(extvars SHARED EXCLUDE_FROM_ALL ${EXTVARSCOMMON_SRC})
target_link_libraries(extvars pointerlist luasignal pthread)