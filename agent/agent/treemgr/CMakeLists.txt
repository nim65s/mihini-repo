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

ADD_SUBDIRECTORY(handlers/extvars)

ADD_LUA_LIBRARY(agent_treemgr DESTINATION agent/treemgr
    init.lua db.lua build.lua table.lua
    =handlers/constant.lua =handlers/table.lua =handlers/functable.lua
    =handlers/cellular.lua
)
ADD_DEPENDENCIES(agent_treemgr cdb cdb_make)

SET(MAP_SRC ${CMAKE_CURRENT_SOURCE_DIR}/maps)
SET(MAP_DST ${CMAKE_INSTALL_PREFIX}/resources)
SET(HDL_SRC ${CMAKE_CURRENT_SOURCE_DIR}/handlers)
SET(HDL_DST ${CMAKE_INSTALL_PREFIX}/lua/agent/treemgr/handlers)

# TODO: move with aleosstub
# If aleosstub is built, install its map
ADD_CUSTOM_TARGET(agent_treemgr_treehdlsample
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/treehdlsample.map ${MAP_DST}/treehdlsample.map)

ADD_CUSTOM_TARGET(agent_treemgr_agentconfig
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/agentconfig.lua ${HDL_DST}/agentconfig.lua
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/agentconfig.map ${MAP_DST}/agentconfig.map)

ADD_CUSTOM_TARGET(agent_treemgr_appcon
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/appcon.lua ${HDL_DST}/appcon.lua
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/appcon.map ${MAP_DST}/appcon.map)

ADD_CUSTOM_TARGET(agent_treemgr_update
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/update.lua ${HDL_DST}/update.lua
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/update.map ${MAP_DST}/update.map)

ADD_CUSTOM_TARGET(agent_treemgr_ramstore
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/ramstore.lua ${HDL_DST}/ramstore.lua
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/ramstore.map ${MAP_DST}/ramstore.map)

# Not installed by default
ADD_CUSTOM_TARGET(agent_treemgr_time
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/time.lua ${HDL_DST}/time.lua
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/time.map ${MAP_DST}/time.map)

ADD_CUSTOM_TARGET(agent_treemgr_dummy_status_report
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/dummystatusreport.map ${MAP_DST}/dummystatusreport.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/dummystatusreport.lua ${HDL_DST}/dummystatusreport.lua)

ADD_CUSTOM_TARGET(agent_treemgr_gpio
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${MAP_SRC}/gpio.map ${MAP_DST}/gpio.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${HDL_SRC}/gpio.lua ${HDL_DST}/gpio.lua)

ADD_DEPENDENCIES(agent_treemgr_gpio gpio)

ADD_DEPENDENCIES(agent_treemgr
    agent_treemgr_agentconfig
    agent_treemgr_monitoring
    agent_treemgr_appcon
    agent_treemgr_update
    # agent_treemgr_ramstore
    # agent_treemgr_time
    # agent_treemgr_dummy_status_report
    # agent_treemgr_gpio
)

SET(TREEMGR_TEST_DIR ${MIHINI_AGENT_SOURCE_DIR}/agent/tests/treemgr)

ADD_CUSTOM_TARGET(test_agent_treemgr_maps
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TREEMGR_TEST_DIR}/table1.map ${MAP_DST}/table1.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TREEMGR_TEST_DIR}/table2.map ${MAP_DST}/table2.map
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TREEMGR_TEST_DIR}/testramstore.map ${MAP_DST}/testramstore.map
)

ADD_DEPENDENCIES(test_agent_treemgr_maps agent_treemgr_treehdlsample)