#ifndef TOMCRYPT_UTILS_H_
#define TOMCRYPT_UTILS_H_

#include "tomcrypt.h"

#ifdef __OAT_API_VERSION__
#include "adl_global.h"
#else
#include <stdio.h>
#endif

int get_cipher_key(unsigned char* nonce, int size_nonce, int idx_K, unsigned char* key_CK, int size_CK);
int get_plain_bin_key(int key_index, unsigned char* key);
int set_plain_bin_keys(int first_index, int n_keys, unsigned const char *plain_bin_keys);

#endif /* TOMCRYPT_UTILS_H_ */
