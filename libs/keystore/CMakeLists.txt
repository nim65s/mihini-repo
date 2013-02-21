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
project (KEYSTORE)

include_directories(${COMMON_SOURCE_DIR})
include_directories(${LIBTOMCRYPT_SOURCE_DIR}/headers)
include_directories(${LIBTOMMATH_SOURCE_DIR})

set(KEYSTORE_SRC keystore.c)

add_library(keystore SHARED ${KEYSTORE_SRC})
# target_link_libraries(keystore_lib m)
SET_TARGET_PROPERTIES(keystore PROPERTIES COMPILE_FLAGS -fPIC)

add_library(keystore-static EXCLUDE_FROM_ALL STATIC ${KEYSTORE_SRC})
# target_link_libraries(keystore-static m)
SET_TARGET_PROPERTIES(keystore-static PROPERTIES COMPILE_FLAGS -fPIC)
