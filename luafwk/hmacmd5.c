/*******************************************************************************
 *
 * Copyright (c) 2013 Sierra Wireless and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *
 *    Fabien Fleutot for Sierra Wireless - initial API and implementation
 *
 ******************************************************************************/

/* Streaming implementation of HMAC-MD5, for Lua, which retrieves keys from
 * the keystore, and never writes them in Lua-managed memory.
 *
 * Contrary to the reference implementation in the RFC, it doesn't require
 * the whole signed message to be available simultaneously in RAM.
 *
 * Usage:
 *
 *    M = require 'hmacmd5'
 *    hmac_text1_text2 = M.hmac(key_index) :update(text1) :update(text2) :digest()
 *    md5_text1_text2  = M.md5()           :update(text1) :update(text2) :digest()
 */

#include <strings.h>
#include <stddef.h>
#include <malloc.h>
#include "md5.h"
#include "lauxlib.h"
#include "keystore.h"

#define DIGEST_LEN 16
#define KEY_LEN    64

struct hmac_ctx_t {
    MD5_CTX md5;
    unsigned char key[KEY_LEN];
    int digested;
};

/* Check that value at Lua stack index `idx` is a userdata containing an hmac context. */
static struct hmac_ctx_t *checkhmac ( lua_State *L, int idx) {
    return (struct hmac_ctx_t *) luaL_checkudata( L, idx, "HMAC_CTX");
}

/* Check that value at Lua stack index `idx` is a userdata containing md5 context. */
static MD5_CTX *checkmd5 ( lua_State *L, int idx) {
    return (MD5_CTX *) luaL_checkudata( L, idx, "MD5_CTX");
}

/* hmac(idx_K) returns a ctx as userdata. */
static int api_hmac( lua_State *L) {
    int i;
    int idx_K = luaL_checkinteger( L, 1)-1;
    struct hmac_ctx_t *ctx = lua_newuserdata( L, sizeof( * ctx));
    bzero( & ctx->key, KEY_LEN);
    i = get_plain_bin_key( idx_K, ctx->key);
    if( i) { lua_pushnil( L); lua_pushinteger( L, i); return 2; }
    ctx->digested = 0; // digest not computed yet
    luaL_newmetatable( L, "HMAC_CTX");
    lua_setmetatable( L, -2);
    for( i=0; i<KEY_LEN; i++) ctx->key[i] ^= 0x36; // convert key into k_ipad
    MD5Init( & ctx->md5);
    MD5Update( & ctx->md5, ctx->key, KEY_LEN);
    for( i=0; i<KEY_LEN; i++) ctx->key[i] ^= 0x36 ^ 0x5c; // convert key from k_ipad to k_opad
    return 1;
}

/* hmac_ctx:update(data) returns hmac_ctx, processes data. */
static int api_hmac_update( lua_State *L) {
    struct hmac_ctx_t *ctx = checkhmac ( L, 1);
    size_t datalen;
    unsigned const char *data = (unsigned const char *) luaL_checklstring( L, 2, & datalen);
    if( ctx->digested) { lua_pushnil( L); lua_pushliteral( L, "digest already computed"); return 2; }
    MD5Update( & ctx->md5, data, datalen);
    lua_pushvalue( L, 1);
    return 1;
}

/* digest(ctx) returns the hmac signature of all data passed to update(). */
static int api_hmac_digest( lua_State *L) {
    struct hmac_ctx_t *ctx = checkhmac ( L, 1);
    unsigned char digest[DIGEST_LEN];

    if( ctx->digested) { lua_pushnil( L); lua_pushliteral( L, "digest already computed"); return 2; }
    ctx->digested = 1;

    MD5Final( digest, & ctx->md5);  // (inner) digest = MD5(k_ipad..msg)
    MD5Init( & ctx->md5); // reuse MD5 ctx to compute outer MD5
    MD5Update( & ctx->md5, ctx->key, KEY_LEN); // key = k_opad
    MD5Update( & ctx->md5, digest, DIGEST_LEN);
    MD5Final( digest, & ctx->md5); // (outer) digest = MD59(k_opad..inner digest)
    lua_pushlstring( L, (const char *) digest, DIGEST_LEN);
    return 1;
}

/* Helper for ltn12 filter. */
static int hmac_filter_closure( lua_State *L) {
    struct hmac_ctx_t *ctx = checkhmac ( L, lua_upvalueindex( 1));
    if( ctx->digested) { lua_pushnil( L); lua_pushliteral( L, "digest already computed"); return 2; }
    if( ! lua_isnil( L, 1)) {
        size_t size;
        const char *data = luaL_checklstring( L, 1, & size);
        MD5Update( & ctx->md5, data, size);
    }
    /* return the original argument, unmodified. */
    lua_settop( L, 1);
    return 1;
}

/* Returns an ltn2 filter, which lets data go through it unmodified but updates the hmac context. */
static int api_hmac_filter( lua_State *L) {
    checkhmac ( L, 1);
    lua_settop( L, 1);
    lua_pushcclosure( L, hmac_filter_closure, 1);
    return 1;
}

/* md5() returns an MD5 ctx as userdata. */
static int api_md5( lua_State *L) {
    MD5_CTX *ctx = lua_newuserdata( L, sizeof( MD5_CTX));
    luaL_newmetatable( L, "MD5_CTX");
    lua_setmetatable( L, -2);
    MD5Init( ctx);
    return 1;
}


/* md5_ctx:update(data) returns md5_ctx, processes data. */
static int api_md5_update( lua_State *L) {
    MD5_CTX *ctx = checkmd5 ( L, 1);
    size_t datalen;
    unsigned const char *data = (unsigned const char *) luaL_checklstring( L, 2, & datalen);
    MD5Update( ctx, data, datalen);
    lua_pushvalue( L, 1);
    return 1;
}

/* md5_ctx:digest() returns the MD5 of all data passed to update(). */
static int api_md5_digest( lua_State *L) {
    MD5_CTX *ctx = checkmd5 ( L, 1);
    unsigned char digest[DIGEST_LEN];
    MD5Final( digest, ctx);
    lua_pushlstring( L, (const char *) digest, DIGEST_LEN);
    return 1;
}

/* Helper for ltn12 filter. */
static int md5_filter_closure( lua_State *L) {
    MD5_CTX *ctx = checkmd5 ( L, lua_upvalueindex( 1));
    if( ! lua_isnil( L, 1)) {
        size_t size;
        const char *data = luaL_checklstring( L, 1, & size);
        MD5Update( ctx, (unsigned char *) data, size);
        lua_pushvalue( L, 1);
        return 1;
    }
    /* return the original argument, unmodified. */
    lua_settop( L, 1);
    return 1;
}

/* Returns an ltn2 filter, which lets data go through it unmodified but updates the md5 context. */
static int api_md5_filter( lua_State *L) {
    checkmd5 ( L, 1);
    lua_settop( L, 1);
    lua_pushcclosure( L, md5_filter_closure, 1);
    return 1;
}

int luaopen_hmacmd5( lua_State *L) {
#define REG(c_name, lua_name) lua_pushcfunction( L, c_name); lua_setfield( L, -2, lua_name)

    /* Build M */
    lua_newtable( L); // M
    REG( api_hmac, "hmac");
    REG( api_md5, "md5");

    /* Build HMAC metatable. */
    luaL_newmetatable( L, "HMAC_CTX"); // M, hmac_mt
    lua_newtable( L);                  //  M, hmac_mt, hmac_index
    lua_pushvalue( L, -1);             //  M, hmac_mt, hmac_index, hmac_index
    lua_setfield( L, -3, "__index");   // M, hmac_mt[__index=hmac_index], hmac_index
    REG( api_hmac_update, "update");
    REG( api_hmac_digest, "digest");
    REG( api_hmac_filter, "filter");
    lua_pop( L, 2);// M

    /* Build MD5 metatable. */
    luaL_newmetatable( L, "MD5_CTX");  // M, md5_mt
    lua_newtable( L);                  //  M, md5_mt, md5_index
    lua_pushvalue( L, -1);             //  M, md5_mt, md5_index, md5_index
    lua_setfield( L, -3, "__index");   // M, md5_mt[__index=md5_index], md5_index
    REG( api_md5_update, "update");
    REG( api_md5_digest, "digest");
    REG( api_md5_filter, "filter");
    lua_pop( L, 2);// M

    return 1;
#undef REG
}


