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

add_subdirectory(scripts/luafwk)
add_subdirectory(scripts/embedded)
add_subdirectory(scripts/testmanagers)
add_subdirectory(scripts/tools)


ADD_CUSTOM_TARGET(embeddedtests_install
        COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/defaultconfig.lua ${CMAKE_LUA_LIBRARY_OUTPUT_DIRECTORY}/agent/defaultconfig.lua        
        )


add_lua_library(embeddedtests DESTINATION tests EXCLUDE_FROM_ALL)

add_dependencies(embeddedtests embeddedtestslua lxp embeddedtests_install embeddedtestmanagers embeddedtestsluafwk luafwktests readyagenttests update_test embeddedteststools readyagentconnectortests modbusserializertests cryptotools web
# Embedded C racon framework
unittest_av_test unittest_dt_test unittest_sms_test unittest_sys_test unittest_updatetest unittest_emp_test unittest_dset_test
# Embedded Lua racon framework
unittest_devicetree unittest_sms unittest_system unittest_emp)


add_custom_target(start_dev_test
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_SOURCE_DIR}/tests/tools/start_dev_test.lua ${CMAKE_INSTALL_PREFIX}/start_dev_test.lua
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/tests/tools/testwrapperfwk ${CMAKE_INSTALL_PREFIX}/testwrapperfwk
)
add_dependencies(start_dev_test lua)
