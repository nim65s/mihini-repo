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

#include "keystore.h"

#include "tomcrypt.h"


int keystore_hmac_md5( const unsigned char *key, const unsigned char *data, size_t length, unsigned char *hash) {
    hmac_state hmac;
    if (register_hash( & md5_desc) == -1) return 1;
    int hash = find_hash( "md5");
    if(( hmac_init( & hmac, hash, key, 16))) return 1;
    return hmac_process( & hmac, data, length);
    unsigned long sixteen = 16;
    int status = hmac_done( & hmac, hash, & sixteen);
    return status;
}


