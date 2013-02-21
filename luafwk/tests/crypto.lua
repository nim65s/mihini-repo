-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Gilles Cannenterre for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local u = require 'unittest'

local F = [[This is a message digest library for Lua 5.1. It is based on the digest routines
provided by OpenSSL. The library can be built to compute the following digests:
md2, md4, md5, sha1, sha224, sha256, sha384, sha512, ripemd160, mdc2.
For more information on these digests, see
	http://en.wikipedia.org/wiki/MD2_(cryptography)
	http://en.wikipedia.org/wiki/MD4
	http://en.wikipedia.org/wiki/MD5
	http://en.wikipedia.org/wiki/SHA_hash_functions
	http://en.wikipedia.org/wiki/RIPEMD-160
	http://en.wikipedia.org/wiki/MDC2
	http://en.wikipedia.org/wiki/Message_digest

OpenSSL is available at
	http://www.openssl.org/
If you're running Unix, you probably already have OpenSSL installed.

If you have trouble finding C source code for MD5 or SHA1 digests that
does not depend on OpenSSL, please send me a note.

To try the library, edit Makefile to reflect your installation of Lua and
then run make. This will build the library and run a simple test.
For detailed installation instructions, see
	http://www.tecgraf.puc-rio.br/~lhf/ftp/lua/install.html

There is no manual but the library is simple and intuitive; see the summary
below. Read also test.lua, which shows the library in action.

This code is hereby placed in the public domain.
Please send comments, suggestions, and bug reports to lhf@tecgraf.puc-rio.br .

-------------------------------------------------------------------------------

digest library:
 __tostring(c) 		 new() 			 version
 clone(c) 		 reset(c)
 digest(c or s,[raw]) 	 update(c,s)

-------------------------------------------------------------------------------
]]

local hash = require 'crypto.hash'
local hmac = require 'crypto.hmac'
local cipher = require 'crypto.cipher'
local rng = require 'crypto.rng'

local t = u.newtestsuite("crypto")

local function test_hash_filter(h, digest)
    h:reset()
    for i=1,#F,10 do
        h:update(string.sub(F, i, i+9))
    end
    u.assert_equal(digest, h:digest())

    local filter = h:reset():filter()
    for i=1,#F,10 do
        local s = string.sub(F, i, i+9)
        u.assert_equal(s, filter(s))
    end
    u.assert_equal(digest, h:digest())
end

local function test_hash(name, checksum)
    local h, err = hash.new(name)
    u.assert_not_nil(h, err)
    h:update("hello "):update("guys")
    local val = h:digest();
    u.assert_equal(val, hash.digest(name, "hello guys"))
    u.assert_equal(checksum, hash.digest(name, F))
    test_hash_filter(h, checksum)
end

function t:test_hash()
    test_hash("md5", "876e33dfc2a7cd1e46e534d0c00fd4f1")
    test_hash("sha1", "e189103170f22bbb25fc6251ef3724c98f2be033")
    test_hash("sha224", "37c8c186ed4d7a86249b593deb1741b36c7d6c32b7bd71bf9e67f3f5")
    test_hash("sha256", "05ac5c8d98b2a089d87fc911848ba3767d1190dad091dff89010794808ed754a")
    --test_hash("sha384", "285e6a2ea0ac429146a363e06cc21237579a84aa2529e92605393d03e0fe22d7bbddeecc74e8a3e3e343b11a40a81ab8")
    --test_hash("sha512", "72adc6409162f81b8ceca616bd5bf931a740c2416ba23a38385f7052e7061bdea66c90fa78847f4df37287e4d072a585d9dfa91428c7f112507fadfee9582300")
end

local function test_hmac_hash(hash)
	local mac1, err1 = hmac.new(hash)
	u.assert_not_nil(mac1, err1)
	local mac2, err2 = hmac.new(hash)
	u.assert_not_nil(mac2, err2)
	local filter = mac2:filter()
    for i=1,#F,10 do
        local s = string.sub(F, i, i+9)
        mac1:update(s)
        filter(s)
    end
    local d1 = mac1:digest()
    local d2 = mac2:digest()
    u.assert_not_nil(d1)
    u.assert_not_nil(d2)
    u.assert_equal(d1, d2)
    u.assert_equal(d1, hmac.digest(hash, F))
end

function t:test_hmac()
    test_hmac_hash({name="md5", keyidx=1})
    test_hmac_hash({name="sha1", keyidx=2})
    test_hmac_hash({name="sha256", keyidx=1})
    test_hmac_hash({name="sha224", keyidx=2})
    --test_hmac_hash({name="sha512", keyidx=2})
    --test_hmac_hash({name="sha384", key="1251523654256548"})
end

local function test_cipher_filter(desc, mode, padding)
    desc.mode = "enc"
    local cipher, err = cipher.new(desc, mode)
    u.assert_not_nil(cipher, err)
    local filter = cipher:filter(padding)
    local crypted = {}
    local data
    for i=1,#F,10 do
        local s = string.sub(F, i, i+9)
        data, err = filter(s)
        u.assert_not_nil(data, err)
        table.insert(crypted, data)
    end
    data, err = filter(nil)
    u.assert_not_nil(data, err)
    table.insert(crypted, data)

    desc.mode = "dec"
    cipher = cipher.new(desc, mode)
    filter = cipher:filter(padding)
    local plaintext = {}
    for i,v in ipairs(crypted) do
        data, err = filter(v)
        u.assert_not_nil(data, err)
        table.insert(plaintext, data)
    end
    data, err = filter(nil)
    u.assert_not_nil(data, err)
    table.insert(plaintext, data)

    u.assert_equal(F, table.concat(plaintext))
end

local function test_cipher_mode(desc, mode)
    local cipher1, err1 = cipher.new(desc, mode)
    u.assert_not_nil(cipher1, err1)
    local cipher2, err2 = cipher.new(desc, mode)
    u.assert_not_nil(cipher2, err2)
    for i=1,#F,256 do
        local s = string.sub(F, i, i+255)
        u.assert_equal(cipher1:process(s), cipher2:process(s))
    end
    for i=1,#F,15 do
        local s = string.sub(F, i, i+14)
        u.assert_equal(cipher1:process(s), cipher2:process(s))
    end
end

function t:test_cipher()
    test_cipher_mode({name="aes", mode="enc", salt="2", keyidxL=1, keyidxR=2, keysize=16},{name="ecb"})
    test_cipher_mode({name="aes", mode="dec", salt="2", keyidxL=1, keyidxR=2, keysize=16},{name="ecb"})
    test_cipher_mode({name="aes", mode="enc", key="12345678912345671234567891234567"},{name="cbc", iv="azertyuiopqsdfgh"})
    test_cipher_mode({name="aes", mode="dec", key="12345678912345671234567891234567"},{name="cbc", iv="azertyuiopqsdfgh"})
    test_cipher_mode({name="aes", mode="enc", salt="2", keyidxL=1, keyidxR=2, keysize=32},{name="ctr", iv="azertyuiopqsdfgh"})
    test_cipher_mode({name="aes", mode="dec", salt="2", keyidxL=1, keyidxR=2, keysize=32},{name="ctr", iv="azertyuiopqsdfgh"})

    --test_cipher_filter({name="aes", keyidx=1},{name="ecb"},{name="none"})
    test_cipher_filter({name="aes", mode="enc", salt="2", keyidxL=1, keyidxR=2, keysize=16},{name="ecb"},{name="pkcs5"})
    --test_cipher_filter({name="aes", key="1254256542154565"},{name="cbc", iv="azertyuiopqsdfgh"},{name="none"})
    test_cipher_filter({name="aes", mode="enc", salt="2", keyidxL=1, keyidxR=2, keysize=16},{name="cbc", iv="azertyuiopqsdfgh"},{name="pkcs5"})
    test_cipher_filter({name="aes", mode="enc", salt="2", keyidxL=1, keyidxR=2, keysize=16},{name="ctr", iv="azertyuiopqsdfgh"},{name="none"})
    test_cipher_filter({name="aes", mode="enc", salt="2", keyidxL=1, keyidxR=2, keysize=32},{name="ctr", iv="azertyuiopqsdfgh"},{name="pkcs5"})
end

function t:test_rng()
    local handle = rng.new()
    for j=1,100 do
        u.assert_not_equal(handle:read(16,true), handle:read(16,true))
   	    u.assert_not_equal(handle:read(128,true), handle:read(128,true))
    end
end

