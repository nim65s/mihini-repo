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

add_lua_library(luafwktests DESTINATION tests EXCLUDE_FROM_ALL
                luatobin.lua  persist.lua rpc.lua sched.lua socket.lua logstore.lua crypto.lua posixsignal.lua
               )

add_lua_library(readyagentconnectortests DESTINATION tests EXCLUDE_FROM_ALL
    stagedb.lua bysant.lua airvantage.lua devicetree.lua sms.lua system.lua asset_tree.lua
)

add_unit_test(devicetree devicetree.lua)
add_unit_test(sms sms.lua TEST_DEPENDENCY messaging_stubs)
if(SHARKS_DEV_BUILD)
  add_unit_test(system system.lua TEST_DEPENDENCY system_stubs)
else()
  add_unit_test(system system.lua)
endif()
add_unit_test(emp emp.lua TEST_DEPENDENCY emp_server)
