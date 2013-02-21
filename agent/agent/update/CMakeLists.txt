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

add_lua_library(update_linux DESTINATION agent/update
	init.lua builtinupdaters.lua omaconnector.lua pkgcheck.lua updatemgr.lua common.lua downloader.lua
)

add_lua_library(update_tools EXCLUDE_FROM_ALL DESTINATION agent/update/tools
    tools/createpkg.lua
)


