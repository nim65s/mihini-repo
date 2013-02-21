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

add_lua_library(treemgr DESTINATION agent/treemgr
	init.lua db.lua build.lua table.lua
	=handlers/agentconfig.lua =handlers/monitoring.lua
	=handlers/ramstore.lua    =handlers/table.lua
	=handlers/time.lua        =handlers/functable.lua
	=handlers/cellular.lua    =handlers/appcon.lua
	=handlers/update.lua      =handlers/constant.lua
)

# If aleosstub is built, install its map
ADD_CUSTOM_TARGET(treemgr_treehdlsample
	COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/treehdlsample.map ${CMAKE_INSTALL_PREFIX}/resources/treehdlsample.map)
ADD_DEPENDENCIES(treehdlsample treemgr_treehdlsample)

# If aleosvars is built, install its map (ADD_DEPENDENCIES performed in aleosvars' makefile)
ADD_CUSTOM_TARGET(treemgr_aleosvars
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/aleos.map ${CMAKE_INSTALL_PREFIX}/resources/aleos.map)


ADD_CUSTOM_TARGET(treemgr_agentconfig
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/agentconfig.map ${CMAKE_INSTALL_PREFIX}/resources/agentconfig.map)

ADD_CUSTOM_TARGET(treemgr_monitoring
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/monitoring.map ${CMAKE_INSTALL_PREFIX}/resources/monitoring.map)

ADD_CUSTOM_TARGET(treemgr_appcon
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/appcon.map ${CMAKE_INSTALL_PREFIX}/resources/appcon.map)

ADD_CUSTOM_TARGET(treemgr_update
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/update.map ${CMAKE_INSTALL_PREFIX}/resources/update.map)

ADD_CUSTOM_TARGET(treemgr_ramstore
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/ramstore.map ${CMAKE_INSTALL_PREFIX}/resources/ramstore.map)

# Not installed by default
ADD_CUSTOM_TARGET(treemgr_time
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/time.map ${CMAKE_INSTALL_PREFIX}/resources/time.map)

ADD_DEPENDENCIES(treemgr treemgr_agentconfig treemgr_monitoring treemgr_appcon treemgr_ramstore treemgr_update)

