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


SET(SHARKS_DEV_BUILD true)
SET(RA_MAJOR_VERSION 8)
SET(RA_MINOR_VERSION 0-DEV)

SET(SHARKS_IP_ADDR 192.168.14.31)
OPTION(SHARKS_IFACE_ETH "The project must be installed remotely on sharks device connected through ethernet"  "OFF")

IF(${SHARKS_IFACE_ETH} STREQUAL "ON")
  SET(SHARKS_IP_ADDR 192.168.13.31)
ENDIF(${SHARKS_IFACE_ETH} STREQUAL "ON")

SET(BUILD_OUTPUT
  ${EMBEDDED_BINARY_DIR}/runtime/bin
  ${EMBEDDED_BINARY_DIR}/runtime/lib
  ${EMBEDDED_BINARY_DIR}/runtime/lua
  ${EMBEDDED_BINARY_DIR}/runtime/resources
  ${EMBEDDED_BINARY_DIR}/runtime/start.sh
)


SET(EMBEDDED_REMOTE_TARGET_DIR /mnt/user/readyagent_${RA_MAJOR_VERSION}.${RA_MINOR_VERSION})
SET(UNITTEST_PREFIX_CMD "sshpass -p v3r1fym3 ssh root@${SHARKS_IP_ADDR}")

# Don't generate a rpath relative to the build tree
SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
SET(CMAKE_INSTALL_RPATH "${EMBEDDED_REMOTE_TARGET_DIR}/lib")
SET(TEST_SCRIPT ${EMBEDDED_BINARY_DIR}/runtime/start_dev_test.lua)

INSTALL(
  CODE "MESSAGE(STATUS \"Install project to sharks device ${SHARKS_IP_ADDR}, in ${EMBEDDED_REMOTE_TARGET_DIR} \")"
  CODE "EXECUTE_PROCESS(COMMAND sshpass -p v3r1fym3 ssh root@${SHARKS_IP_ADDR} \"test -d ${EMBEDDED_REMOTE_TARGET_DIR} || mkdir ${EMBEDDED_REMOTE_TARGET_DIR}\" )"
  CODE "EXECUTE_PROCESS(COMMAND sshpass -p v3r1fym3 scp -r ${BUILD_OUTPUT} root@${SHARKS_IP_ADDR}:${EMBEDDED_REMOTE_TARGET_DIR})"
  CODE "EXECUTE_PROCESS(COMMAND sshpass -p v3r1fym3 ssh root@${SHARKS_IP_ADDR} \"chown -R rauser:rauser ${EMBEDDED_REMOTE_TARGET_DIR}\" )"
)
