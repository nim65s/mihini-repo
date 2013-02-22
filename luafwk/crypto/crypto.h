/*******************************************************************************
 * Copyright (c) 2012 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Gilles Cannenterre for Sierra Wireless - initial API and implementation
 *******************************************************************************/
#ifndef LTOMCRYPT_H_
#define LTOMCRYPT_H_

#include "tomcrypt.h"
#include "keystore.h"

#include "lua.h"
#include "lauxlib.h"

#define CHECK(X) \
    do { \
        int status = X; \
        if (status != CRYPT_OK) { \
            lua_pushnil(L); \
            lua_pushstring(L, error_to_string(status)); \
            return 2; \
        } \
    } while (0);

#define AUTHOR      "libtomcryp " SCRYPT

LUALIB_API int luaopen_crypto_hash(lua_State* L);
LUALIB_API int luaopen_crypto_cipher(lua_State *L);
LUALIB_API int luaopen_crypto_hmac(lua_State *L);
LUALIB_API int luaopen_crypto_rng(lua_State *L);

#endif
