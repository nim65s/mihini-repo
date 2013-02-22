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

ADD_LUA_LIBRARY(agent_treemgr DESTINATION agent/treemgr
    init.lua db.lua build.lua table.lua
    =handlers/agentconfig.lua =handlers/constant.lua
    =handlers/ramstore.lua    =handlers/table.lua
    =handlers/time.lua        =handlers/functable.lua
    =handlers/cellular.lua    =handlers/appcon.lua
    =handlers/update.lua      
)
ADD_DEPENDENCIES(agent_treemgr cdb cdb_make)

# If aleosstub is built, install its map
ADD_CUSTOM_TARGET(agent_treemgr_treehdlsample
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/treehdlsample.map ${CMAKE_INSTALL_PREFIX}/resources/treehdlsample.map)
ADD_DEPENDENCIES(agent_treemgr_treehdlsample treemgr_treehdlsample)

# If aleosvars is built, install its map (ADD_DEPENDENCIES performed in aleosvars' makefile)
ADD_CUSTOM_TARGET(agent_treemgr_aleosvars
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/aleos.map ${CMAKE_INSTALL_PREFIX}/resources/aleos.map)

ADD_CUSTOM_TARGET(agent_treemgr_agentconfig
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/agentconfig.map ${CMAKE_INSTALL_PREFIX}/resources/agentconfig.map)

ADD_CUSTOM_TARGET(agent_treemgr_appcon
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/appcon.map ${CMAKE_INSTALL_PREFIX}/resources/appcon.map)

ADD_CUSTOM_TARGET(agent_treemgr_update
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/update.map ${CMAKE_INSTALL_PREFIX}/resources/update.map)

ADD_CUSTOM_TARGET(agent_treemgr_ramstore
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/ramstore.map ${CMAKE_INSTALL_PREFIX}/resources/ramstore.map)

# Not installed by default
ADD_CUSTOM_TARGET(agent_treemgr_time
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/time.map ${CMAKE_INSTALL_PREFIX}/resources/time.map)

ADD_CUSTOM_TARGET(agent_treemgr_dummy_status_report
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/maps/dummystatusreport.map ${CMAKE_INSTALL_PREFIX}/resources/dummystatusreport.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/handlers/dummystatusreport.lua ${CMAKE_INSTALL_PREFIX}/lua/agent/treemgr/handlers/dummystatusreport.lua)

ADD_DEPENDENCIES(agent_treemgr agent_treemgr_agentconfig agent_treemgr_monitoring
    agent_treemgr_appcon agent_treemgr_ramstore agent_treemgr_update)

SET( TREEMGR_TEST_DIR ${MIHINI_AGENT_SOURCE_DIR}/agent/tests/treemgr)

ADD_CUSTOM_TARGET(test_agent_treemgr_maps
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TREEMGR_TEST_DIR}/table1.map ${CMAKE_INSTALL_PREFIX}/resources/table1.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TREEMGR_TEST_DIR}/table2.map ${CMAKE_INSTALL_PREFIX}/resources/table2.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TREEMGR_TEST_DIR}/testramstore.map ${CMAKE_INSTALL_PREFIX}/resources/testramstore.map
)

