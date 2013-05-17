#*******************************************************************************
# Copyright (c) 2013 Sierra Wireless and others.
# All rights reserved. This building script is made available under the terms
# of the Eclipse Public License v1.0 which accompanies this distribution, and
# is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Sierra Wireless - initial API and implementation
#*******************************************************************************

PROJECT(OPENAES)

INCLUDE_DIRECTORIES(${LIB_OPENAES_SOURCE_DIR} ${LIB_MIHINI_KEYSTORE_SOURCE_DIR} ${LIB_MD5_SOURCE_DIR})

ADD_LUA_LIBRARY(openaes_core openaes_core.c DESTINATION openaes)
TARGET_LINK_LIBRARIES(openaes_core lib_openaes)
SET_TARGET_PROPERTIES(openaes_core PROPERTIES OUTPUT_NAME core)

ADD_LUA_LIBRARY(openaes_isaac openaes_isaac.c DESTINATION openaes)
TARGET_LINK_LIBRARIES(openaes_isaac lib_openaes)
SET_TARGET_PROPERTIES(openaes_isaac PROPERTIES OUTPUT_NAME isaac)

