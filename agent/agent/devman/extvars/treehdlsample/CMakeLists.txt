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

include_directories(
    ${COMMON_SOURCE_DIR}
    ${LIBALEOSVARS_SOURCE_DIR}
    ${EXTVARSCOMMON_SOURCE_DIR}
    ${LIB_LINUX_SOURCE_DIR}
)

add_lua_library(treehdlsample EXCLUDE_FROM_ALL DESTINATION agent/devman/extvars treehdlsample.c)
target_link_libraries(treehdlsample extvars Swi_Log)
