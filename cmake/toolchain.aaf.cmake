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

# this one is important
SET(CMAKE_SYSTEM_NAME Linux)
#this one not so much
SET(CMAKE_SYSTEM_VERSION 1)

# specify the cross compiler
SET(CMAKE_C_COMPILER   /opt/airlink/sharks/bin/arm-marvell-linux-gnueabi-gcc)
SET(CMAKE_CXX_COMPILER /opt/airlink/sharks/bin/arm-marvell-linux-gnueabi-g++)

# where is the target environment
SET(CMAKE_FIND_ROOT_PATH  /opt/airlink/sharks)

# search for programs in the build host directories
#SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# add define for loader module
SET(LOADER_PATH_BASE "/mnt/user/readyagent/apps")

SET(SHARKS_BUILD true)

ADD_DEFINITIONS(-std=c99 -fno-strict-aliasing -D_POSIX_C_SOURCE=199309L -D_XOPEN_SOURCE=600 -D_BSD_SOURCE)
