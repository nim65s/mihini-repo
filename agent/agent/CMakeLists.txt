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

add_lua_library(readyagenttests DESTINATION tests EXCLUDE_FROM_ALL
    tests/config.lua
    # tests/monitoring.lua # currently disabled
    tests/aleosstub.lua tests/time.lua
    tests/mediation.lua tests/mediationtestserver.lua tests/treemgr.lua
    tests/appcon.lua tests/treemgr/treemgr_table1.lua
    tests/treemgr/treemgr_table2.lua
)

ADD_CUSTOM_TARGET(treemgr_test_maps
	COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/tests/treemgr/table1.map ${CMAKE_INSTALL_PREFIX}/resources/table1.map
	COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/tests/treemgr/table2.map ${CMAKE_INSTALL_PREFIX}/resources/table2.map
	COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/tests/treemgr/testramstore.map ${CMAKE_INSTALL_PREFIX}/resources/testramstore.map
)

ADD_DEPENDENCIES(readyagenttests treemgr_test_maps)
ADD_DEPENDENCIES(readyagenttests treemgr_test_handlers)


add_lua_library(update_test EXCLUDE_FROM_ALL DESTINATION tests
    tests/update/update.lua
)

ADD_CUSTOM_COMMAND(TARGET update_test PRE_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/tests/update/test_packages ${CMAKE_INSTALL_PREFIX}/update/tmp/test_packages
)

add_dependencies(update_test update_tools)

add_lua_library(readyagent DESTINATION agent
    init.lua modem.lua time.lua config.lua mediation.lua netman.lua migration.lua
    autoexec.lua

    =srvcon/init.lua 
    =srvcon/transport/http.lua 
    =srvcon/transport/tcp.lua
    =srvcon/session/security.lua
    =srvcon/session/provisionning.lua
    =srvcon/session/default.lua

    # Monitoring currently out-of-date
    # =monitoring/init.lua  =monitoring/cellular.lua =monitoring/luamem.lua =monitoring/netman.lua

    =devman/init.lua =devman/cmds/ExecuteScript.lua =devman/cmds/LogUpload.lua =devman/cmds/ReadNode.lua
    =devman/cmds/SoftwareUpdate.lua =devman/cmds/TCPRemoteConnect.lua =devman/cmds/appcon.lua
    =devman/cmds/ResetToFactoryDefault.lua =devman/cmds/Reboot.lua

    =asscon/datamanager.lua =asscon/init.lua =asscon/sms.lua
 )

add_lua_library(readyagent_transport_servers DESTINATION agent EXCLUDE_FROM_ALL
    =srvcon/transport/tcpserver.lua
    =srvcon/transport/httpserver.lua)

add_subdirectory(devman/extvars)

add_lua_library(readyagentlinux DESTINATION agent
    appcon.lua bearer.lua boot.lua defaultconfig.lua platform.lua
)

add_lua_library(setpreshared DESTINATION agent EXCLUDE_FROM_ALL setpreshared.lua)

add_subdirectory(treemgr)
add_subdirectory(system)
add_subdirectory(update)
