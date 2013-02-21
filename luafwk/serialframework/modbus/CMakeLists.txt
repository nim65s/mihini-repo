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

set(LIBMODBUS_SRC
    lua_modbus_serializer.c
    ${LUASERIALPROTOCOLS_SOURCE_DIR}/common/lua_serial_fwk.c
)

include_directories(
    ${COMMON_SOURCE_DIR}
    ${SERIALPROTOCOLS_SOURCE_DIR}/common/
    ${LUASERIALPROTOCOLS_SOURCE_DIR}/common/
    ${LIBMODBUSCORE_SOURCE_DIR}
)

add_lua_library(modbus EXCLUDE_FROM_ALL ${LIBMODBUS_SRC})
add_lua_library(modbustcp EXCLUDE_FROM_ALL modbustcp.lua)
add_dependencies(modbustcp modbus)
target_link_libraries(modbus modbus-core)

add_lua_library(modbusserializertests DESTINATION tests EXCLUDE_FROM_ALL 
                test/modbusserializer.lua)
add_dependencies(modbusserializertests modbus)

add_lua_library(modbusserial EXCLUDE_FROM_ALL modbus.lua)
add_dependencies(modbusserial modbus)
