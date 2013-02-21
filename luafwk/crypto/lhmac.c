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

#define MYNAME      "hmac"
#define MYVERSION   MYNAME " library for " LUA_VERSION " / May 2011 / using " AUTHOR
#define MYTYPE      MYNAME " handle"

typedef struct SHmacDesc_ {
    int keyidx;
    size_t keysize;
    int hash_id;
    unsigned char* key;
} SHmacDesc;

typedef struct SHmac_ {
    SHmacDesc desc;
    hmac_state state;
} SHmac;

static int get_hmac_desc(lua_State* L, int index, SHmacDesc* desc) {
    if (lua_istable(L, index)) {
        lua_getfield(L, index, "name");
        const char* name = NULL;
        if (!lua_isnil(L, -1))
            name = lua_tostring(L, -1);
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
            lua_pushstring(L, "'desc.name' should be a known hash");
            return 2;
        }
        desc->hash_id = find_hash(name);
        if (desc->hash_id == -1) {
            lua_pushnil(L);
            lua_pushstring (L, "cannot find hash implementation");
            return 2;
        }
        lua_pop(L, 1);

        lua_getfield(L, 1, "keyidx");
        desc->keyidx = -1;
        if (!lua_isnil(L, -1)) {
            desc->keyidx = (int)lua_tointeger(L, -1);
            if (desc->keyidx < 1) {
                lua_pushnil(L);
                lua_pushstring(L, "'desc.keyidx' should be > 0");
                return 2;
            }
        }
        lua_pop(L, 1);

        lua_getfield(L, 1, "key");
        desc->key = NULL;
        if (!lua_isnil(L, -1))
            desc->key = (unsigned char*)lua_tolstring(L, -1, &(desc->keysize));
        lua_pop(L, 1);

    } else {
        lua_pushnil(L);
        lua_pushstring(L, "'desc' should be a table");
        return 2;
    }
    return 0;
}

/** new(hash, key) */
static int Lnew(lua_State* L) {
    SHmac* hmac = (SHmac*) lua_newuserdata(L, sizeof(SHmac));
    hmac->desc.key = NULL; // mark as invalid.
    luaL_getmetatable(L, MYTYPE);
    lua_setmetatable(L, -2);

    int param = get_hmac_desc(L, 1, &(hmac->desc));
    if (param > 0)
        return param;

    unsigned char* key = NULL;
    unsigned char keycrypt[16];
    if (hmac->desc.keyidx > 0) {
        hmac->desc.keysize = 16;
        if (get_plain_bin_key(hmac->desc.keyidx, keycrypt) != CRYPT_OK) {
             lua_pushnil(L);
             lua_pushstring (L, "cannot retrieve key from keystore");
             return 2;
        }
        key = keycrypt;
    } else {
        key = hmac->desc.key;
    }

    int status = CRYPT_ERROR;
    if (key != NULL)
        status = hmac_init( & (hmac->state), hmac->desc.hash_id,
                (const unsigned char*) key,
                (unsigned long) hmac->desc.keysize);
    if (key == keycrypt)
        memset(keycrypt, 0, 16);
    if (status != CRYPT_OK) {
        lua_pushnil( L);
        lua_pushstring( L, error_to_string(status));
        return 2;
    }
    return 1;
}

/** update(userdata, s) */
static int Lupdate(lua_State* L) {
    SHmac* hmac = luaL_checkudata(L, 1, MYTYPE);
    size_t in_size;
    unsigned char* in = (unsigned char*) luaL_checklstring(L, 2, &in_size);
    CHECK(hmac_process(&(hmac->state), in, (unsigned long) in_size));
    lua_settop(L, 1);
    return 1;
}

/** digest(userdata, [raw]) or digest(hash, key, s)*/
static int Ldigest(lua_State* L) {
    unsigned char dst[MAXBLOCKSIZE];
    unsigned long dstlen = MAXBLOCKSIZE;
    int i;
    if (lua_isuserdata(L, 1)) {
        SHmac* hmac = luaL_checkudata(L, 1, MYTYPE);
        hmac_state hstmp = hmac->state;
        hstmp.key = malloc(hash_descriptor[hmac->desc.hash_id].blocksize);
        memcpy(hstmp.key, hmac->state.key, hash_descriptor[hmac->desc.hash_id].blocksize);
        CHECK(hmac_done(&hstmp, dst, &dstlen));
        i = 2;
    } else {
        SHmacDesc desc;        
        int param = get_hmac_desc(L, 1, &desc);
        if (param > 0)
            return param;
        
        unsigned char* key = NULL;
        unsigned char keycrypt[16];
        if (desc.keyidx > 0) {
            desc.keysize = 16;
            if (get_plain_bin_key(desc.keyidx, keycrypt) != CRYPT_OK) {
                 lua_pushnil(L);
                 lua_pushstring (L, "cannot retrieve key from keystore");
                 return 2;
            }
            key = keycrypt;
        } else {
            key = desc.key;
        }
        
        size_t in_size;
        unsigned char* in = (unsigned char*) luaL_checklstring(L, 2, &in_size);
        
        int status = CRYPT_ERROR;
        if (key != NULL)
            status = hmac_memory(desc.hash_id, (const unsigned char*) key, (unsigned long) desc.keysize, in, (unsigned long) in_size, dst, &dstlen);
        if (key == keycrypt)
            memset(keycrypt, 0, 16);
        if (status != CRYPT_OK) {
            lua_pushnil(L);
            lua_pushstring(L, error_to_string(status));
            return 2;
        }
        i = 3;
    }
    if (lua_toboolean(L, i))
        lua_pushlstring(L, (const char *) dst, dstlen);
    else {
        char hex[2 * MAXBLOCKSIZE + 1];
        for (i = 0; i < dstlen; i++)
            sprintf(hex + 2 * i, "%02x", dst[i]);
        lua_pushlstring(L, hex, 2*dstlen);
    }
    return 1;
}

/** tostring(userdata) */
static int Ltostring(lua_State* L) {
    SHmac* p = luaL_checkudata(L, 1, MYTYPE);
    lua_pushfstring(L, "%s %p", MYTYPE, (void*) p);
    return 1;
}

static int hmac_filter(lua_State* L) {
    SHmac* hmac = luaL_checkudata(L, lua_upvalueindex(1), MYTYPE);
    if (lua_isnil(L, 1)) {
        lua_pushnil(L);
    } else  {
        size_t in_size;
        const char* in = luaL_checklstring(L, 1, &in_size);
        if (in_size > 0)
            CHECK(hmac_process(&(hmac->state), (unsigned char*)in, (unsigned long) in_size));
        lua_pushlstring(L, in, in_size);
    }
    return 1;
}

/** filter(userdata, s) */
static int Lfilter(lua_State* L) {
    luaL_checkudata(L, 1, MYTYPE);
    lua_pushvalue(L, -1);
    lua_pushcclosure (L, hmac_filter, 1);
    return 1;
}

static int Ldone(lua_State* L) {
    unsigned char dst[MAXBLOCKSIZE];
    unsigned long dstlen = MAXBLOCKSIZE;
    SHmac* hmac = luaL_checkudata(L, 1, MYTYPE);
    if( NULL == hmac->desc.key) {
        printf( "Attempt to clean an uninitialized hmac handle\n");
    } else {
        CHECK(hmac_done(&(hmac->state), dst, &dstlen));
    }
    return 0;
}

static const luaL_Reg R[] = {
        { "__gc", Ldone },
        { "digest", Ldigest },
        { "filter", Lfilter },
        { "new", Lnew },
        { "tostring", Ltostring },
        { "update", Lupdate },
        { NULL, NULL } };

int luaopen_crypto_hmac(lua_State* L) {
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
