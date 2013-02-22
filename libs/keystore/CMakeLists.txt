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
PROJECT(LIB_MIHINI_KEYSTORE)

INCLUDE_DIRECTORIES(${LIB_MIHINI_COMMON_SOURCE_DIR})
INCLUDE_DIRECTORIES(${LIB_TOMCRYPT_SOURCE_DIR}/headers)
INCLUDE_DIRECTORIES(${LIB_TOMMATH_SOURCE_DIR})

SET(KEYSTORE_SRC keystore.c)

ADD_LIBRARY(lib_keystore SHARED ${KEYSTORE_SRC})
# TARGET_LINK_LIBRARIES(lib_keystore m)
SET_TARGET_PROPERTIES(lib_keystore PROPERTIES COMPILE_FLAGS -fPIC OUTPUT_NAME keystore)

ADD_LIBRARY(lib_keystore_static EXCLUDE_FROM_ALL STATIC ${KEYSTORE_SRC})
# TARGET_LINK_LIBRARIES(lib_keystore_static m)
SET_TARGET_PROPERTIES(lib_keystore_static PROPERTIES COMPILE_FLAGS -fPIC OUTPUT_NAME keystore_static)
