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
 *    Gilles Cannenterre for Sierra Wireless - initial API and implementation
 *    Fabien Fleutot     for Sierra Wireless - initial API and implementation
 *
 ******************************************************************************/
#include "keystore.h"

#include "tomcrypt.h"

#define CRYPT_OK 0
#define CRYPT_ERROR 1

/* Define this to get verbose traces and sanity-checks when writing.
 * Warning: traces leak sensitive informations! */
//#define DBG_KEYSTORE

#ifdef DBG_KEYSTORE
#define DBG_TRACE( args) printf args
#else
#define DBG_TRACE( args)
#endif

int keystore_get_obfuscation_bin_key( int key_index, unsigned char *obfuscation_bin_key);

/* Initializes a symmetric ECB cipher context, to obfuscate or deobfuscate keys.
 * Used by `get_plain_bin_key` and `set_plain_bin_keys`.
 *
 * Sensitive local variables to clean: none
 *
 * @param ecb_ctx the encryption context to initialize.
 * @param obfuscation_bin_key the key to use for obfuscation.
 * @return CRYPT_OK or CRYPT_ERROR.
 */
static int get_ecb_obfuscator(
        symmetric_ECB *ecb_ctx,
        unsigned const char *obfuscation_bin_key) {
    if( register_cipher( & aes_desc) == -1) return CRYPT_ERROR;

    if( ecb_start(
        find_cipher( "aes"),
        (const unsigned char*) obfuscation_bin_key,
        16, 0, ecb_ctx))
        return CRYPT_ERROR;
    else return CRYPT_OK;
}

int keystore_obfuscate( int index, unsigned char *obfuscated_bin_key, unsigned const char *plain_bin_key) {
    unsigned char obfuscation_bin_key[16];
    symmetric_ECB ecb_ctx;
    if( keystore_get_obfuscation_bin_key( index, obfuscation_bin_key)) return CRYPT_ERROR;
    DBG_TRACE(( "Obfuscation key #%d =\t%s\n", first_index+i, k2s(obfuscation_bin_key)));
    if( get_ecb_obfuscator( & ecb_ctx, obfuscation_bin_key)) {
        memset( obfuscation_bin_key, 0, 16);
        return CRYPT_ERROR;
    }
    int status = ecb_encrypt( plain_bin_key, obfuscated_bin_key, 16, & ecb_ctx);
    DBG_TRACE(( "Plain key #%d =   \t%s\n", index, k2s((unsigned char*) plain_bin_keys + 16*i)));
    DBG_TRACE(( "Obfuscated key #%d =\t%s\n", first_index+i, k2s(obfuscated_bin_keys + 16*i)));
    memset( & ecb_ctx, 0, sizeof( ecb_ctx));
    memset( obfuscation_bin_key, 0, 16);
    return status;
}

int keystore_deobfuscate( int key_index, unsigned char *plain_bin_key, unsigned const char *obfuscated_bin_key) {
    unsigned char obfuscation_bin_key[16];
    if( keystore_get_obfuscation_bin_key( key_index, obfuscation_bin_key)) return CRYPT_ERROR;
    DBG_TRACE(( "Obfuscation key #%d =\t%s\n", key_index, k2s(obfuscation_bin_key)));
    symmetric_ECB ecb_ctx;
    if( get_ecb_obfuscator( & ecb_ctx, (unsigned const char *) obfuscation_bin_key)) {
        memset( obfuscation_bin_key, 0, 16);
        return CRYPT_ERROR;
    }
    int status = ecb_decrypt( obfuscated_bin_key, plain_bin_key, 16, & ecb_ctx);
    memset( obfuscation_bin_key, 0, 16);
    if( status) { return CRYPT_ERROR; }
    else {
        DBG_TRACE(( "Plain key #%d =   \t%s\n", key_index, k2s(plain_bin_key)));
        return CRYPT_OK;
    }
}
