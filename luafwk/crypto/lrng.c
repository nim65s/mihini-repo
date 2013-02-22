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
#include "crypto.h"

#define MYNAME      "rng"
#define MYVERSION   MYNAME " library for " LUA_VERSION " / May 2011 / using " AUTHOR
#define MYTYPE      MYNAME " handle"

#define ENTROPY 128

/** new() */
static int Lnew(lua_State* L) {
    prng_state* prng = (prng_state*) lua_newuserdata(L, sizeof(prng_state));
    luaL_getmetatable(L, MYTYPE);
    lua_setmetatable(L, -2);
    int idx = find_prng("fortuna");
    if (idx == -1) {
        lua_pushnil(L);
        lua_pushstring (L, "cannot find 'fortuna' implementation");
        return 2;
    }
    CHECK(rng_make_prng(ENTROPY, idx, prng, NULL));
    return 1;
}

/** read(userdata, [size], [raw]) */
static int Lread(lua_State* L) {
    prng_state* prng = luaL_checkudata(L, 1, MYTYPE);
    int size = luaL_optint(L, 2, 128);
    unsigned char* buf = (unsigned char*) malloc(size);
    if (buf == NULL) {
        lua_pushnil(L);
        lua_pushstring (L, "allocation error");
        return 2;
    }
    if (fortuna_read(buf, (unsigned long) size, prng) != size) {
        free(buf);
        lua_pushnil(L);
        lua_pushstring (L, "'fortuna' read error");
        return 2;
    }
    if (lua_toboolean(L, 3))
        lua_pushlstring(L, (const char*)buf, size);
    else {
        char* hex = (char*) malloc(2*size + 1);
        if (hex == NULL) {
            free(buf);
            lua_pushnil(L);
            lua_pushstring (L, "allocation error");
            return 2;
        }
        int i;
        for (i = 0; i < size; i++)
            sprintf(hex + 2 * i, "%02x", buf[i]);
        lua_pushlstring(L, (const char*)hex, 2*size);
        free(hex);
    }
    free(buf);
    return 1;
}

/** tostring(userdata) */
static int Ltostring(lua_State* L) {
    prng_state* p = luaL_checkudata(L, 1, MYTYPE);
    lua_pushfstring(L, "%s %p", MYTYPE, (void*) p);
    return 1;
}

/** done(userdata) */
static int Ldone(lua_State* L) {
    prng_state* prng = luaL_checkudata(L, 1, MYTYPE);
    int status = fortuna_done(prng);
    if (status != CRYPT_OK) {
        lua_pushnil(L);
        lua_pushstring(L, error_to_string(status));
    }
    return 0;
}

static const luaL_Reg R[] = {
        { "__gc", Ldone },
        { "new", Lnew },
        { "read", Lread },
        { "tostring", Ltostring },
        { NULL, NULL } };

int luaopen_crypto_rng(lua_State* L) {
    if (register_prng(&fortuna_desc) == -1)
        luaL_error(L, "'fortuna' registration has failed\n");

    luaL_newmetatable(L, MYTYPE);
    lua_setglobal(L, MYNAME);
    luaL_register(L, MYNAME, R);
    lua_pushliteral(L, "version");
    lua_pushliteral(L, MYVERSION);
    lua_settable(L, -3);
    lua_pushliteral(L, "__index");
    lua_pushvalue(L, -2);
    lua_settable(L, -3);
    lua_pushliteral(L, "__tostring");
    lua_pushliteral(L, "tostring");
    lua_gettable(L, -3);
    lua_settable(L, -3);
    return 1;
}
