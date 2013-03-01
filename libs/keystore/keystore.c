/*******************************************************************************
 *
 * Copyright (c) 2012 Sierra Wireless and others.
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

#include "keystore.h"
#include "stdlib.h"

/* Define this to get verbose traces and sanity-checks when writing.
 * Warning: traces leak sensitive informations! */
//#define DBG_KEYSTORE

#ifdef DBG_KEYSTORE
#define DBG_TRACE( args) printf args
#else
#define DBG_TRACE( args)
#endif

static int get_obfuscation_bin_key( int key_index, unsigned char *key);
static unsigned char htod(char hex);
static int get_obfuscated_bin_key(int key_index, unsigned char* obfuscated_bin_key);
static int set_obfuscated_bin_keys( int first_index, int n_keys, unsigned const char *obfuscated_bin_keys);

#ifdef DBG_KEYSTORE
/* Convert a bin key into printable hex string, for debug traces.
 * Warning: only one buffer, each call voids what's returned by previous ones. */
static char *k2s(unsigned char *k) {
    int i;
    static char buff[3*16+1];
    for( i=0; i<16; i++)
        sprintf( buff+3*i, "%02x ", k[i]);
    buff[3*16-1]='\0';
    return buff;
}
#endif

/* Computes and returns the encryption/decryption symmetric key.
 * The cipher key is normally derived from the primary key K as follows:
 *
 *     CK = HMAC_MD5( K, nonce)
 *
 * If the key CK is longer than an MD5, (AES keys are 256bits whereas MD5
 * is only 128bits), we append the HMAC of (nonce..nonce), the nonce
 * concatenated to itself, to the HMAC of the nonce, in order to get a
 * 256 bits key:
 *
 *     CK = HMAC_MD5(K, nonce) .. HMAC_MD5(K, nonce..nonce).
 *
 * Sensitive local variables to clean: key_K (on stack)
 *
 * *WARNING*: In Lua, key indexes are 1-based, whereas in C they are 0-based.
 *   Key number n in Lua is called n-1 in C.
 *
 * @param nonce salt string
 * @param size_nonce number of characters in nonce
 * @param idx_K key index of the main password key (0-based)
 * @param key_CK where the cipher key is written
 * @params key_CK size of the expected key, in bytes. Must be either 16 or 32
 *   (128 bits or 256 bits).
 * @return CRYPT_OK or CRYPT_ERROR
 */
int get_cipher_key(unsigned char* nonce, int size_nonce, int idx_K, unsigned char* key_CK, int size_CK) {
    unsigned char key_K[16];

    /* Preliminary sanity checks */
    if( ! key_CK || ! nonce) return CRYPT_ERROR;
    if (register_hash( & md5_desc) == -1) return CRYPT_ERROR;
    if(128/8 != size_CK && 256/8 != size_CK) return CRYPT_ERROR;

    /* Retrieve keys keyidxL and keyidxR (read and decipher from file,
     * put both in keytmp. */
    if(( get_plain_bin_key( idx_K, key_K))) goto failure;

    DBG_TRACE(( "\nget_cipher_key()\nPlain cipher key K =\t%s\n", k2s( key_K)));

    /* Part common to 128 and 256 bits keys: CK[0...15] = MD5(K, nonce). */
    hmac_state hmac;
    int hash = find_hash( "md5");
    unsigned long sixteen = 16;

    if(( hmac_init( & hmac, hash, (const unsigned char*) key_K, 16))) goto failure;
    if(( hmac_process( & hmac, nonce, size_nonce))) goto failure;
    if(( hmac_done( & hmac, key_CK, & sixteen))) goto failure;

    DBG_TRACE(( "nonce (size=%d) =\t%s\n", size_nonce, k2s( nonce)));

    DBG_TRACE(( "hmac(K, nonce) =\t%s\n", k2s( key_CK)));

    /* Part specific to 256 bits keys: CK[16...31] = MD5(K, nonce..nonce). */
    if(256/8 == size_CK) {
        if(( hmac_init( & hmac, hash, (const unsigned char*) key_K, 16))) goto failure;
        if(( hmac_process( & hmac, nonce, size_nonce))) goto failure;
        if(( hmac_process( & hmac, nonce, size_nonce))) goto failure;
        if(( hmac_done( & hmac, key_CK+16, & sixteen))) goto failure;
    }

    memset( key_K, 0, sizeof( key_K));
    return CRYPT_OK;

    failure:
    memset( key_K, 0, sizeof( key_K));
    return CRYPT_ERROR;
}


/* Puts the obfuscation key in `obfuscation_bin_key`.
 *
 * No sensitive local variable that can be cleared.
 *
 * @param key_index the 0-based index of the key whose (des)obfuscation is
 *   requested. different key indexes should have different obfuscated
 *   representations, to avoid making it obvious when the same key is used at
 *   several places.
 * @param obfuscation_bin_key where the obfuscation/desobfuscation key is written.
 * @return CRYPT_OK (cannot fail)
 */
static int get_obfuscation_bin_key( int key_index, unsigned char *obfuscation_bin_key) {
    unsigned const char unrotated_obfuscation_key[16] = {
        0x12, 0x95, 0xF2, 0xDC,
        0x21, 0x59, 0x2F, 0xCD,
        0x95, 0x21, 0xDC, 0x2F,
        0xFE, 0xDA, 0xBE, 0xBE };
    int i;
    for( i = 0; i < 16; i++) {
        obfuscation_bin_key[i] = unrotated_obfuscation_key[(i + key_index) % 16];
    }
    return CRYPT_OK;
}

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

/* Retrieves the key at `key_index` from file, and deobfuscates it. Resulting plain
 * key is written in plain_bin_key.
 *
 * Sensitive local variables to clean:
 *   obfuscation_bin_key (on stack).
 *
 * @param key_index 0-based index of the key to retrieve.
 * @param plain_bin_key where the resulting key is written.
 * @return CRYPT_OK or CRYPT_ERROR.
 */
int get_plain_bin_key( int key_index, unsigned char* plain_bin_key) {
     unsigned char obfuscation_bin_key[16], obfuscated_bin_key[16];

     DBG_TRACE(( "\nGetting key #%d\n", key_index));

    if( get_obfuscation_bin_key( key_index, obfuscation_bin_key)) return CRYPT_ERROR;

    DBG_TRACE(( "Obfuscation key #%d =\t%s\n", key_index, k2s(obfuscation_bin_key)));

    symmetric_ECB ecb_ctx;
    if( get_ecb_obfuscator( & ecb_ctx, (unsigned const char *) obfuscation_bin_key)) {
        memset( obfuscation_bin_key, 0, 16);
        return CRYPT_ERROR;
    }

    if( get_obfuscated_bin_key( key_index, obfuscated_bin_key)) goto failure;
    DBG_TRACE(( "Obfuscated key #%d =\t%s\n", key_index, k2s(obfuscated_bin_key)));
    if( ecb_decrypt( obfuscated_bin_key, plain_bin_key, 16, & ecb_ctx)) goto failure;
    DBG_TRACE(( "Plain key #%d =   \t%s\n", key_index, k2s(plain_bin_key)));

    memset( obfuscation_bin_key, 0, 16);
    return CRYPT_OK;

    failure:
    memset( obfuscation_bin_key, 0, 16);
    return CRYPT_ERROR;
}

/* Obfuscates and writes the keys `key_index ... key_index + n_keys - 1` in the file.
 *
 * Sensitive local variables to clean: obfuscation_bin_key (on stack), ecb_ctx (on stack).
 *
 * @param key_index 0-based index of the first key to write.
 * @param n_keys number of keys to write.
 * @param plain_bin_keys keys to write, concatenated in order.
 * @return CRYPT_OK or CRYPT_ERROR.
 */
int set_plain_bin_keys(int first_index, int n_keys, unsigned const char *plain_bin_keys) {
    unsigned char obfuscation_bin_key[16], *obfuscated_bin_keys=NULL;
    symmetric_ECB ecb_ctx;
    int status = CRYPT_ERROR; // will be updated to CRYPT_OK when everything will have succeeded

    obfuscated_bin_keys = malloc( 16 * n_keys);
    if( ! obfuscated_bin_keys) goto cleanup;


    DBG_TRACE(( "\nSetting keys #%d...#%d\n", first_index, first_index+n_keys-1));
    int i;
    for( i=0; i<n_keys; i++) {
        if( get_obfuscation_bin_key( first_index+i, obfuscation_bin_key)) goto cleanup;
        DBG_TRACE(( "Obfuscation key #%d =\t%s\n", first_index+i, k2s(obfuscation_bin_key)));
        if( get_ecb_obfuscator( & ecb_ctx, obfuscation_bin_key)) goto cleanup;
        if( ecb_encrypt( plain_bin_keys + 16*i, obfuscated_bin_keys + 16*i, 16, & ecb_ctx)) goto cleanup;
        DBG_TRACE(( "Plain key #%d =   \t%s\n", first_index+i, k2s((unsigned char*) plain_bin_keys + 16*i)));
        DBG_TRACE(( "Obfuscated key #%d =\t%s\n", first_index+i, k2s(obfuscated_bin_keys + 16*i)));
    }

    if( set_obfuscated_bin_keys( first_index, n_keys, obfuscated_bin_keys)) goto cleanup;

    status = CRYPT_OK;

#ifdef DBG_KEYSTORE
    for( i=0; i<n_keys; i++) {
        unsigned char tmp[16];
        get_plain_bin_key( first_index+i, tmp);
        if( memcmp( tmp, plain_bin_keys+16*i, 16)) {
            printf( "After writing keys #%d...#%d, failed to read back key %d\n",
                    first_index, first_index+n_keys-1, first_index+i);
            assert( 0);
        }
        memset( tmp, 0, 16);
    }
    printf( "Successfully verified the read-back of keys #%d...#%d\n",
            first_index, first_index+n_keys-1);
#endif

    cleanup:
    if( obfuscated_bin_keys) {
        memset( obfuscated_bin_keys, 0, 16);
        free( obfuscated_bin_keys);
    }
    memset( obfuscation_bin_key, 0, 16);
    memset( & ecb_ctx, 0, sizeof( ecb_ctx));

    return status;
}

/* Converts hexa ASCII char [0-9a-fA-F] into the int it represents. */
static unsigned char htod(char hex) {
    unsigned char dec = 0;
    if ((hex >= 'A') && (hex <= 'F'))       dec = hex - 'A' + 0xA;
    else if ((hex >= 'a') && (hex <= 'f'))  dec = hex - 'a' + 0xa;
    else if ((hex >= '0') && (hex <= '9'))  dec = hex - '0' + 0;
    return dec;
}


static FILE *get_file( const char *modes){
    char buffer[256];
    const char *rw_path;
    rw_path = getenv("LUA_AF_RW_PATH");
    if( rw_path) {
        int len = strlen( rw_path);
        strncpy( buffer, rw_path, sizeof( buffer)-sizeof( KEYSTORE_FILE_NAME));
        if( buffer[len-1] != '/') { strcpy( buffer+len, "/"); len++; }
        strncpy(buffer+len, KEYSTORE_FILE_NAME, sizeof( buffer)-len);
    } else {
        strcpy( buffer, "./");
        strncpy( buffer+2, KEYSTORE_FILE_NAME, sizeof( buffer)-3);
    }
    return fopen( buffer, modes);
}

/* Retrieves obfuscated key from file. To be used by `read_plain_bin_key`.
 *
 * *WARNING*: In Lua, key indexes are 1-based, whereas in C they are 0-based.
 *   Key number n in Lua is called n-1 in C.
 *
 * Sensitive local variables to clean: none (everything is still obfuscated).
 *
 * @param key_index 0-based index of the key to retrieve.
 * @param obfuscated_bin_key where the key will be written.
 * @return CRYPT_OK or CRYPT_ERROR.
 */
static int get_obfuscated_bin_key(int key_index, unsigned char* obfuscated_bin_key) {
    if( ! obfuscated_bin_key) return CRYPT_ERROR;
    FILE* file = get_file( "rb");
    if ( ! file) return CRYPT_ERROR;
    if( fseek( file, 33 * key_index, SEEK_SET)) { fclose( file); return CRYPT_ERROR; }

    /* Retrieve the hexa form of the key (key are stored in order, take 33 chars each) */
    unsigned char obfuscated_hex_key[33];
    int status =
        0 != fseek( file, 33 * key_index, SEEK_SET) ||
        33 != fread( obfuscated_hex_key, 1, 33, file);

    fclose(file);
    if( status) return CRYPT_ERROR;

    /* Convert hex to bin */
    int i; for (i = 0; i < 16; i++) obfuscated_bin_key[i] =
            0x10 * htod(obfuscated_hex_key[2*i]) + htod(obfuscated_hex_key[2*i+1]);

    return CRYPT_OK;
}

/* Writes obfuscated key into file. To be used by `write_plain_bin_key`.
 * Sensitive local variables to clean: none (everything is already obfuscated).
 *
 * @param first_index 0-based index of the first key to write.
 * @param n_keys number of keys to write.
 * @param obfuscated_bin_keys key to write, concatenated together.
 * @return CRYPT_OK or CRYPT_ERROR.
 */
static int set_obfuscated_bin_keys( int first_index, int n_keys, unsigned const char *obfuscated_bin_keys) {
    char *content = NULL;
    size_t sz = 0;
    int status = CRYPT_ERROR; /* will be changed to CRYPT_OK after everything succeeded */
    int i, n;

    /* Determine the file's size. */
    if( ! obfuscated_bin_keys) return CRYPT_ERROR;
    FILE* file = get_file( "rb");
    if ( ! file) { content=NULL; sz=0; } /* empty file. */
    else { /* file found, return content and size. */
        if( fseek( file, 0, SEEK_END)) goto cleanup;
        sz = ftell( file);
        content = malloc( sz);
        if( ! content) goto cleanup;

        /* Read the whole file into `content`. */
        if( fseek( file, 0, SEEK_SET)) goto cleanup;
        n = fread( content, 1, sz, file);
        if( n != sz) goto cleanup;
        fclose( file); /* closed for reading, will reopen for writing later. */
        file = NULL;
    }

    /* If the content image is too short to contain all new keys, lengthen it.
     * One byte is represented by 2 characters [0-9a-z], plus a final '\n', so
     * a 16 bytes key takes up 33 file characters. */
    int needed_sz = 33 * (first_index+n_keys);
    if( sz < needed_sz) {
        /* Can't use realloc(), because I need to clear the key from memory
         * in case of failure. */
        char *new_content = malloc( needed_sz);
        if( ! new_content) goto cleanup;
        memcpy( new_content, content, sz);
        memset( content, 0, sz);
        free( content);
        content = new_content;
        memset( content+sz, '0', needed_sz-sz);
        for( i=sz+32; i<needed_sz; i+=33) content[i] = '\n';
        sz = needed_sz;
    }

    /* Convert hex to bin, directly in file content image. */
    for( i=0; i<n_keys; i++) {
        int j;
        for( j=0; j<16; j++) {
            int offset = 33*(first_index+i) + 2*j;
            int byte   = obfuscated_bin_keys[16*i + j];
            char *target = content + offset;
            sprintf( target, "%02x", byte);
        }
        content[33*(first_index+i)+32] = '\n';
    }

    /* Write back file content */
    file = get_file( "wb");
    if( ! file) goto cleanup;
    n = fwrite( content, 1, sz, file);
    if( n == sz) status = CRYPT_OK;

    /* Clean up */
    cleanup:
    if( file) fclose( file);
    if( content) { memset( content, 0, sz); free( content); }
    return status;
}
