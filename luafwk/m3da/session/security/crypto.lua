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

-- Cryptographic helpers for security sessions, based on OpenAES and
-- RFC reference implementation of MD5.

local core  = require 'openaes.core'
local hash  = require 'hmacmd5'
local isaac = require 'openaes.isaac'
local M = { }

-- OpenAES expects a header to describe configuration, in front of data to decrypt
local OAES_HEADER="OAES\001\002\002\000\000\000\000\000\000\000\000\000"

-------------------------------------------------------------------------------
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
    if scheme ~= 'aes-cbc-128' then return nil, "scheme not supported" end
    assert(#ciphered_text % 16 == 0, "bad ciphered_text size")
    local iv    = hash.md5():update(nonce):digest()
    local oaes  = core.new(nonce, keyidx)
    local plain = core.decrypt(oaes, OAES_HEADER..iv..ciphered_text)
    local n = plain :byte(-1)
    assert(0<n and n<=16)
    return plain :sub (1, -n-1)
end

-------------------------------------------------------------------------------
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
    if scheme ~= 'aes-cbc-128' then return nil, "scheme not supported" end
    local iv = hash.md5():update(nonce):digest()  -- initialization vector
    local oaes = core.new(nonce, keyidx, iv)
    local buffer = ''      -- yet unsent data (must be sent by 16-bytes chunks)
    local lastsent = false -- has last padded segment been sent yet?
    local function filter(data)
        if lastsent then return nil
        elseif data=='' then return ''
        elseif data==nil then -- end-of-stream, flush last padded chunk
            local n = 16 - #buffer
            assert(0<n and n<=16)
            buffer = buffer .. string.char(n) :rep(n)
            -- There a header + IV, added by OpenAES, to remove.
            local result = core.encrypt(oaes, buffer) :sub(33, -1)
            lastsent = true
            return result
        else -- non-last chunk, send all completed 16-byte chunks, keep the remainder in buffer
            buffer = buffer..data
            if #buffer < 16 then return '' -- not enough data, keep in buffer until more data arrives
            else -- send every completed 16-bytes chunks
                local nkept = #buffer % 16 -- how many bytes must be kept in buffer
                local tosend = buffer :sub (1, -nkept-1)
                local tokeep = buffer :sub (-nkept, -1)
                buffer = tokeep
                local result = core.encrypt(oaes, tosend) :sub(33, -1)
                return result
            end
        end
    end
    return filter
end

-------------------------------------------------------------------------------
--- Returns a new 16 bytes (128 bits) random string.
function M.getnonce() return isaac(16) end

-------------------------------------------------------------------------------
--- Returns an hmac computing object with methods:
--  * `:update(data)` which accept more data to authenticate, and returns
--   the authentication object to allow method chaining;
--  * `:digest(bool)` which returns the digest as a binary string if `bool` is true.
--  @param hash_name name of the hash algorithm, currently `'md5'` or `'sha1'`.
--  @param keyidx the keystore index of the key to use
--  @return an object with methods `:update()` and `:digest()` respecting the
--   specification above, or nil + error message.
function M.hmac(hash_name, keyidx)
    assert(hash_name=='md5', "hash not supported")
    return hash.hmac(keyidx)
end

local function no_ecdh() return nil, 'Elliptic curves not supported' end

-------------------------------------------------------------------------------
--- Returns a private key and a public key for Elliptic-Curve Diffie-Hellman
--  shared secret generation, as a pair of strings.
M.ecdh_new = no_ecdh

-------------------------------------------------------------------------------
--- Generates a shared secret from our private key and the peer's public key.
M.ecdh_getsecret = no_ecdh

return M
