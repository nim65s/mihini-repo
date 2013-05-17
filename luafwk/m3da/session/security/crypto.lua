-------------------------------------------------------------------------------
-- Copyright (c) 2013 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

-- Cryptographic helpers for security sessions, based on LibTomCrypt.

local M = { }

local cipher = require "crypto.cipher"
local hmac   = require "crypto.hmac"
local hash   = require "crypto.hash"
local rng    = require "crypto.rng"
local ecdh   = require "crypto.ecdh"

-- Common helper for `decrypt_function` and `encrypt_filter`.
local function get_cipher(scheme, nonce, mode, keyidx)
    local method, chain, keysize = assert(string.match(scheme, "(.+)%-(.+)%-(%d+)"))
    assert (method and chain and keysize, "failed to parse encryption scheme")
    local obj, err = cipher.new({ -- cipher cfg
        name    = method,
        mode    = mode,
        nonce   = nonce,
        keyidx  = keyidx,
        keysize = keysize/8
    }, { -- chaining cfg
        name = chain,
        iv   = hash.digest("md5", nonce, true)
    })
    -- TODO: modify lcipher to that the padding is passed in cipher.new
    return obj, err
end

--- Decrypts a ciphered payload, passed as a single string
--  @param scheme The encryption scheme, as a string following the pattern
--   "{algorithm}-{chaining}-{keysize}"
--  @param nonce the nonce, shared with the encrypting party, used to prime
--   the ciphered and to get an initial chaining vector.
--  @param keyidx index of the key in the key store, 1-based
--  @param ciphered_text data to decrypt.
--  @return plain text, or nil+error message, or throws an error
function M.decrypt_function(scheme, nonce, keyidx, ciphered_text)
    checks('string', 'string', 'number', 'string')
    local obj = assert(get_cipher(scheme, nonce, 'dec', keyidx))
    local raw_result = assert(obj :process (ciphered_text))
    if scheme :match '%-cbc%-' then -- remove pkcs5 padding
        local n = raw_result :byte (-1)
        return raw_result :sub (1, -n-1)
    else return raw_result end
end

--- Returns an ltn12 filter ciphering a plain text with the appropriate
--  encryption scheme, priming nonce and keystore key.
--  @param scheme The encryption scheme, as a string following the pattern
--   "{algorithm}-{chaining}-{keysize}"
--  @param nonce the nonce, shared with the encrypting party, used to prime
--   the ciphered and to get an initial chaining vector.
--  @param keyidx index of the key in the key store, 1-based
--  @return and ltn12 filter, or nil+error message, or throws an error
function M.encrypt_filter(scheme, nonce, keyidx)
    checks('string', 'string', 'number')
    local obj = assert(get_cipher(scheme, nonce, 'enc', keyidx))
    local padding = scheme :match '%-cbc%-' and 'pkcs5'or 'none'
    return obj :filter {name=padding}
end

local noncegenerator

--- Returns a new 16 bytes (128 bits) random string.
function M.getnonce()
    if not noncegenerator then noncegenerator = rng.new() end
    return noncegenerator :read (16, true)
end

--- Returns an hmac computing object with methods:
--  * `:update(data)` which accept more data to authenticate, and returns
--   the authentication object to allow method chaining
--  * `:digest(bool)` which returns the digest, as an hex string ig `bool` is
--   false/nil, as a binary string if it's true
--  @param hash_name name of the hash algorithm, currently `'md5'` or `'sha1'`.
--  @param keyidx the keystore index of the key to use
--  @return an object with methods `:update()` and `:digest()` respecting the
--   specification above, or nil + error message.
function M.hmac(hash_name, keyidx)
    checks('string', 'number')
    return hmac.new{ name = hash_name, keyidx = keyidx }
end

--- Returns a private key and a public key for Elliptic-Curve Diffie-Hellman
--  shared secret generation, as a pair of strings.
function M.ecdh_new() return ecdh.new() end

--- Generates a shared secret from our private key and the peer's public key.
function M.ecdh_getsecret(my_privkey, their_pubkey)
    return ecdh.getsecret(my_privkey, their_pubkey)
end

return M
