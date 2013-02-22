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

#define MYNAME      "hash"
#define MYVERSION   MYNAME " library for " LUA_VERSION " / May 2011 / using " AUTHOR
#define MYTYPE      MYNAME " handle"

typedef struct SHash_ {
    int hash_id;
    hash_state state;
} SHash;

static SHash* Pget(lua_State* L, int i) {
    return (SHash*) luaL_checkudata(L, i, MYTYPE);
}

static SHash* Pnew(lua_State* L) {
    SHash* hash = lua_newuserdata(L, sizeof(SHash));
    luaL_getmetatable(L, MYTYPE);
    lua_setmetatable(L, -2);
    return hash;
}

/** new() */
static int Lnew(lua_State* L) {
    const char* name = NULL;
    if (!lua_isnil(L, 1))
       name = lua_tostring(L, 1);
    if (name != NULL && strcmp(name, "md5") == 0) {
       register_hash(&md5_desc);
    } else if (name != NULL && strcmp(name, "sha1") == 0) {
       register_hash(&sha1_desc);
    } else if (name != NULL && strcmp(name, "sha224") == 0) {
       register_hash(&sha224_desc);
    } else if (name != NULL && strcmp(name, "sha256") == 0) {
       register_hash(&sha256_desc);
    }
/*
    else if (name != NULL && strcmp(name, "sha384") == 0) {
       register_hash(&sha384_desc);
    }
    else if (name != NULL && strcmp(name, "sha512") == 0) {
       register_hash(&sha512_desc);
    }
*/
    else {
       lua_pushnil(L);
       lua_pushstring(L, "'name' should be a known hash");
       return 2;
    }
    int hash_id = find_hash(name);
    if (hash_id == -1) {
        lua_pushnil(L);
        lua_pushstring (L, "cannot find hash implementation");
        return 2;
    }
    SHash* hash = Pnew(L);
    hash->hash_id = hash_id;
    CHECK(hash_descriptor[hash->hash_id].init(&(hash->state)));
    return 1;
}

/** clone(userdata) */
static int Lclone(lua_State* L) {
    SHash* hash = Pget(L, 1);
    SHash* hashn = Pnew(L);
    *hashn = *hash;
    return 1;
}

/** reset(userdata) */
static int Lreset(lua_State* L) {
    SHash* hash = Pget(L, 1);
    CHECK(hash_descriptor[hash->hash_id].init(&(hash->state)));
    lua_settop(L, 1);
    return 1;
}

/** update(userdata, s) */
static int Lupdate(lua_State* L) {
    size_t size;
    SHash* hash = Pget(L, 1);
    const char* chunk = luaL_checklstring(L, 2, &size);
    CHECK(hash_descriptor[hash->hash_id].process(&(hash->state), (unsigned char*)chunk, (unsigned long)size));
    lua_settop(L, 1);
    return 1;
}

/** digest(userdata, [raw]) or digest(s, [raw])*/
static int Ldigest(lua_State* L) {
    unsigned char digest[MAXBLOCKSIZE];
    int hashsize = MAXBLOCKSIZE;
    int n = 2;
    if (lua_isuserdata(L, 1)) {
        SHash hash = *Pget(L, 1);
        hashsize = hash_descriptor[hash.hash_id].hashsize;
        CHECK(hash_descriptor[hash.hash_id].done(&(hash.state), digest));
    } else {
        size_t size;
        const char* name = NULL;
        if (!lua_isnil(L, 1))
           name = lua_tostring(L, 1);
        if (name != NULL && strcmp(name, "md5") == 0) {
           register_hash(&md5_desc);
        } else if (name != NULL && strcmp(name, "sha1") == 0) {
           register_hash(&sha1_desc);
        } else if (name != NULL && strcmp(name, "sha224") == 0) {
           register_hash(&sha224_desc);
        } else if (name != NULL && strcmp(name, "sha256") == 0) {
           register_hash(&sha256_desc);
        }
        /*
        else if (name != NULL && strcmp(name, "sha384") == 0) {
           register_hash(&sha384_desc);
        }
        else if (name != NULL && strcmp(name, "sha512") == 0) {
           register_hash(&sha512_desc);
        }
        */
        else {
           lua_pushnil(L);
           lua_pushstring(L, "'name' should be a known hash");
           return 2;
        }
        int hash_id = find_hash(name);
        if (hash_id == -1) {
            lua_pushnil(L);
            lua_pushstring (L, "cannot find hash implementation");
            return 2;
        }
        hashsize = hash_descriptor[hash_id].hashsize;
        const char* chunk = luaL_checklstring(L, 2, &size);
        hash_state state;
        CHECK(hash_descriptor[hash_id].init(&state));
        CHECK(hash_descriptor[hash_id].process(&state, (unsigned char*)chunk, (unsigned long)size));
        CHECK(hash_descriptor[hash_id].done(&state, digest));
        n = 3;
    }
    if (lua_toboolean(L, n))
        lua_pushlstring(L, (char*) digest, hashsize);
    else {
        char hex[2 * MAXBLOCKSIZE + 1];
        int i;
        for (i = 0; i < hashsize; i++) {
            sprintf(hex + 2 * i, "%02x", digest[i]);
        }
        lua_pushlstring(L, hex, 2*hashsize);
    }
    return 1;
}

/** tostring(userdata) */
static int Ltostring(lua_State* L) {
    SHash* hash = Pget(L, 1);
    lua_pushfstring(L, "%s %p", MYTYPE, (void*)hash);
    return 1;
}

static int hash_filter(lua_State* L) {
    SHash* hash = Pget(L, lua_upvalueindex(1));
    if (lua_isnil(L, 1)) {
        lua_pushnil(L);
    } else  {
        size_t size;
        const char* chunk = lua_tolstring(L, 1, &size);
        if (size > 0) {
            CHECK(hash_descriptor[hash->hash_id].process(&(hash->state), (unsigned char*)chunk, (unsigned long)size));
        }
        lua_pushlstring(L, chunk, size);
    }
    return 1;
}

/** filter(userdata, s) */
static int Lfilter(lua_State* L) {
    luaL_checkudata(L, 1, MYTYPE);
    lua_pushvalue(L, -1);
    lua_pushcclosure (L, hash_filter, 1);
    return 1;
}

static int Ldone(lua_State* L) {
    unsigned char digest[MAXBLOCKSIZE];
    SHash* hash = Pget(L, 1);
    CHECK(hash_descriptor[hash->hash_id].done(&(hash->state), digest));
    return 0;
}

static const luaL_reg R[] = {
        { "__gc", Ldone },
        { "clone", Lclone },
        { "digest", Ldigest },
        { "filter", Lfilter},
        { "new", Lnew },
        { "reset", Lreset },
        { "tostring", Ltostring },
        { "update", Lupdate },
        { NULL, NULL } };

int luaopen_crypto_hash(lua_State* L) {
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
