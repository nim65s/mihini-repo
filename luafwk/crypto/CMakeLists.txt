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

PROJECT(MIHINI_CRYPTO)

# TODO check whether all the includes are required
INCLUDE_DIRECTORIES(${LIB_TOMCRYPT_SOURCE_DIR}/headers
                    ${LIB_MIHINI_KEYSTORE_SOURCE_DIR}
                    )

ADD_LUA_LIBRARY(crypto_cipher DESTINATION crypto lcipher.c)
TARGET_LINK_LIBRARIES(crypto_cipher lib_tomcrypt lib_keystore)
SET_TARGET_PROPERTIES(crypto_cipher PROPERTIES OUTPUT_NAME cipher)

ADD_LUA_LIBRARY(crypto_hmac DESTINATION crypto lhmac.c)
TARGET_LINK_LIBRARIES(crypto_hmac lib_tomcrypt lib_keystore)
SET_TARGET_PROPERTIES(crypto_hmac PROPERTIES OUTPUT_NAME hmac)

ADD_LUA_LIBRARY(crypto_hash DESTINATION crypto lhash.c)
TARGET_LINK_LIBRARIES(crypto_hash lib_tomcrypt)
SET_TARGET_PROPERTIES(crypto_hash PROPERTIES OUTPUT_NAME hash)

ADD_LUA_LIBRARY(crypto_rng DESTINATION crypto lrng.c)
TARGET_LINK_LIBRARIES(crypto_rng lib_tomcrypt)
SET_TARGET_PROPERTIES(crypto_rng PROPERTIES OUTPUT_NAME rng)

ADD_LUA_LIBRARY(crypto_ecdh DESTINATION crypto lecdh.c)
TARGET_LINK_LIBRARIES(crypto_ecdh lib_tomcrypt lib_tommath)
SET_TARGET_PROPERTIES(crypto_ecdh PROPERTIES OUTPUT_NAME ecdh)
