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

ADD_SUBDIRECTORY(scripts/luafwk)
ADD_SUBDIRECTORY(scripts/embedded)
ADD_SUBDIRECTORY(scripts/testmanagers)
ADD_SUBDIRECTORY(scripts/tools)


ADD_CUSTOM_TARGET(embeddedtests_install
        COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/defaultconfig.lua ${CMAKE_LUA_LIBRARY_OUTPUT_DIRECTORY}/agent/defaultconfig.lua
        )


ADD_LUA_LIBRARY(embeddedtests DESTINATION tests EXCLUDE_FROM_ALL)

ADD_DEPENDENCIES(embeddedtests embeddedtestslua lxp embeddedtests_install embeddedtestmanagers embeddedtestsluafwk luafwktests readyagenttests update_test embeddedteststools readyagentconnectortests modbusserializertests cryptotools web
# Embedded C racon framework
unittest_av_test unittest_dt_test unittest_sms_test unittest_sys_test unittest_updatetest unittest_emp_test unittest_dset_test
# Embedded Lua racon framework
unittest_devicetree unittest_sms unittest_system unittest_emp)
