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

### Lua modules of the agent

ADD_LUA_LIBRARY(agent_modules DESTINATION agent
    init.lua modem.lua time.lua config.lua mediation.lua netman.lua migration.lua
    appcon.lua bearer.lua boot.lua autoexec.lua system.lua rest.lua)

ADD_LUA_LIBRARY(agent_srvcon DESTINATION agent
    srvcon.lua)

ADD_DEPENDENCIES(agent_srvcon
    m3da_transport
    m3da_session
    m3da_session_security)

ADD_SUBDIRECTORY(devman)
ADD_SUBDIRECTORY(treemgr)
ADD_SUBDIRECTORY(update)
ADD_SUBDIRECTORY(asscon)
ADD_SUBDIRECTORY(monitoring)

# optional provisioning module, to easily write crypto keys locally
ADD_LUA_LIBRARY(agent_provisioning DESTINATION agent EXCLUDE_FROM_ALL provisioning.lua)


ADD_DEPENDENCIES(agent_modules

    # Internal dependencies
    agent_devman agent_treemgr agent_system agent_update
    agent_linux agent_asscon   agent_srvcon
    agent_versions  agent_monitoring

    # External dependencies
    mihini_misc # strict, print etc.
    checks coxpcall lfs log pack
    mihini_linux #posixsignal, fdwrapper etc.
    shell_telnet rpc_sched log_tools
    ntp web web_auth

    # Target-specific config
    agent_platform
    )

### Test modules ###

ADD_LUA_LIBRARY(test_agent DESTINATION tests EXCLUDE_FROM_ALL
    tests/config.lua
    tests/monitoring.lua
    tests/aleosstub.lua tests/time.lua
    tests/extvars.lua
    tests/mediation.lua tests/mediationtestserver.lua tests/treemgr.lua
    tests/appcon.lua tests/treemgr/treemgr_table1.lua
    tests/treemgr/treemgr_table2.lua
    tests/update/update.lua
)

ADD_DEPENDENCIES(test_agent test_agent_treemgr_maps treehdlsample)

ADD_CUSTOM_TARGET(test_update_pkgs
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/tests/update/test_packages ${CMAKE_INSTALL_PREFIX}/update/tmp/test_packages
)
ADD_DEPENDENCIES(test_agent test_update_pkgs agent_update_tools)

