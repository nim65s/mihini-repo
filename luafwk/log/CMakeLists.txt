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

include_directories(${COMMON_SOURCE_DIR})
add_lua_library(log_lua    DESTINATION log init.lua tools.lua)
add_lua_library(log_store  DESTINATION log log_store.c log_storeflash.c)
set_target_properties( log_store PROPERTIES OUTPUT_NAME store)


