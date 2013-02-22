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

PROJECT(MIHINI_LOG)

INCLUDE_DIRECTORIES(${LIB_MIHINI_COMMON_SOURCE_DIR})

ADD_LUA_LIBRARY(log DESTINATION log init.lua)
ADD_DEPENDENCIES(log utils checks)

ADD_LUA_LIBRARY(log_tools DESTINATION log tools.lua)
ADD_DEPENDENCIES(log_tools log log_store sched)

ADD_LUA_LIBRARY(log_store  DESTINATION log log_store.c log_storeflash.c)
SET_TARGET_PROPERTIES(log_store PROPERTIES OUTPUT_NAME store)
ADD_DEPENDENCIES(log_store log)
