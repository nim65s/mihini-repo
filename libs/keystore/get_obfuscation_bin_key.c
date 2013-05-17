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

/* Puts the obfuscation key in `obfuscation_bin_key`. Can be replaced by another key
 * and/or another way to keep it stored yet hard to retrieve.
 *
 * No sensitive local variable that can be cleared.
 *
 * @param key_index the 0-based index of the key whose (de)obfuscation is
 *   requested. different key indexes should have different obfuscated
 *   representations, to avoid making it obvious when the same key is used at
 *   several places.
 * @param obfuscation_bin_key where the obfuscation/desobfuscation key is written.
 * @return CRYPT_OK (cannot fail)
 */
int keystore_get_obfuscation_bin_key( int key_index, unsigned char *obfuscation_bin_key) {
    unsigned const char unrotated_obfuscation_key[16] = {
        0x12, 0x95, 0xF2, 0xDC,
        0x21, 0x59, 0x2F, 0xCD,
        0x95, 0x21, 0xDC, 0x2F,
        0xFE, 0xDA, 0xBE, 0xBE };
    int i;
    for( i = 0; i < 16; i++) {
        obfuscation_bin_key[i] = unrotated_obfuscation_key[(i + key_index) % 16];
    }
    return 0;
}
