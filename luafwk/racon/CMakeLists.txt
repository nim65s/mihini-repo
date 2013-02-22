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

PROJECT(MIHINI_RACON)

ADD_LUA_LIBRARY(racon DESTINATION racon
    =asset/init.lua =asset/tree.lua common.lua
    empparser.lua init.lua ipc.lua table.lua system.lua devicetree.lua sms.lua)
ADD_DEPENDENCIES(racon yajl)
