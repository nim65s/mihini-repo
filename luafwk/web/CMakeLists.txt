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

PROJECT(MIHINI_WEB)

ADD_LUA_LIBRARY(web EXCLUDE_FROM_ALL DESTINATION web
    server.lua auth.lua compile.lua session.lua template.lua)
ADD_DEPENDENCIES(web sched socket_sched)

