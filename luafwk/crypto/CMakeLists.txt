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

include_directories(${LIBTOMCRYPT_SOURCE_DIR}/headers 
					${LIBTOMCRYPT_SOURCE_DIR}/ciphers/aes
					${LIBTOMCRYPT_SOURCE_DIR}/hashes/sha2
					${KEYSTORE_SOURCE_DIR}
					)
	
add_lua_library(cipher DESTINATION crypto lcipher.c)
target_link_libraries(cipher tomcrypt keystore)
					
add_lua_library(hmac DESTINATION crypto lhmac.c)
target_link_libraries(hmac tomcrypt keystore)

add_lua_library(hash DESTINATION crypto lhash.c)
target_link_libraries(hash tomcrypt)

add_lua_library(rng DESTINATION crypto lrng.c)
target_link_libraries(rng tomcrypt)

add_lua_library(ecdh DESTINATION crypto lecdh.c)
target_link_libraries(ecdh tomcrypt tommath)
