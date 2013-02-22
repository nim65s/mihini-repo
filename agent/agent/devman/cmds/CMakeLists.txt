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

# TODO: separate commands into separate target, to avoid embedding unnecessary ones

ADD_LUA_LIBRARY(agent_devman_cmds DESTINATION agent/devman/cmds
    ExecuteScript.lua
    LogUpload.lua
    ReadNode.lua
    SoftwareUpdate.lua
    TCPRemoteConnect.lua
    appcon.lua
    ResetToFactoryDefault.lua
    Reboot.lua)

ADD_DEPENDENCIES(agent_devman_cmds
    agent_config
    agent_treemgr
    agent_srvcon
    agent_update
    crypto_hash
    socket
    log_store
    racon
    niltoken
    persist)

