local security = require 'agent.srvcon.session.security'

local ltn12   = require "ltn12"
local bit32   = require 'bit32'
local awtda   = require 'bysant.awtda'
local awtda_deserialize = awtda.deserializer()

local cipher = require "crypto.cipher"
local hmac   = require "crypto.hmac"
local hash   = require "crypto.hash"
local ecdh   = require "crypto.ecdh"


local M = { }
-------------------------------------------------------------------------------
-- Writes the 3 keys needed for encryption and authentication in the key store.
--
function M.setkeys(K, server_id, device_id)
    local KS = hash.new 'md5' :update (server_id) :update (K) :digest(true)
    local KD = hash.new 'md5' :update (device_id) :update (K) :digest(true)
    assert(security.IDX_AUTH_KS == security.IDX_CRYPTO_K + 1)
    assert(security.IDX_AUTH_KD == security.IDX_CRYPTO_K + 2)
    return cipher.write(security.IDX_CRYPTO_K, { K, KS, KD })
end

-------------------------------------------------------------------------------
-- Perform bitwise
local function xor_string(s1, s2)
    assert(#s1==#s2)
    local t1, t2 = { s1 :byte(1, -1) }, { s2 :byte(1, -1) }
    local t3 = { }
    for i=1, #s1 do t3[i] = bit32.bxor(t1[i], t2[i]) end
    return string.char(unpack(t3))
end

-------------------------------------------------------------------------------
-- Requests crypto keys from the server with the provisionning keys,
-- stores them in the keystore for future use.
--
-- The crypto key should be asked only once in the device's lifetime, the first
-- time the agent successfully connects to Internet. 
--
-- The sequence is:
-- * message 1D to server: send a device signing salt against replay attacks.
-- * message 1S from server: receive a server signing salt against replay attacks.
-- * message 2D to server: send a signed DH pubkey to establish shared secret.
-- * message 2S from server: send the 2nd half of DH, signed, and DH-ciphered key K.
-- * message 3D to server: acknowledge provisionning success, signed.
-- 
function M.downloadkeys(getauthentication)

    -- Returns, as a stream source, an envelope with the specified header and
    -- an empty payload.
    local function empty_envelope(hdr)
        local env = awtda.envelope(hdr)
        return ltn12.source.chain(ltn12.source.empty(), env)
    end

    -- Generates signing stuff: an LTN12 filter to pass data trhough, and
    -- an envelope footer generator.
    local function signer(salt)
        local handler, filter = security.getauthentication(security.authentication, IDX_AUTH_KD)
        local function footer()
            filter(salt) 
            return { autoreg_mac = handler :digest (true) }
        end
        return filter, footer
    end 

    -- message 1D: send device signing salt
    local salt_device = security.getnonce()
    local env_1d = empty_envelope{ id = security.deviceid, autoreg_salt = salt_device }
    assert(security.transport.send (env_1d))    -- Second exchange (1): send device pubkey
    
    -- message 1S: receive server signing salt
    local env_1s = assert(security.receive())
    local salt_server = assert(env_1d.header.autoreg_salt)
    
    local pubkey_device, privkey_device = ecdh.new()
    
    -- message 2D: send signed ECC-DH pubkey
    local env_2d_inner = empty_envelope{ autoreg_pubkey=pubkey }
    local filter_2d, footer_2d = signer(salt_server)
    local env_2d_outer = awtda.envelope({ id=M.deviceid },footer_2d)
    local env_2d = ltn12.source.chain(env_2d_inner, filter_2d, env_2d_outer)
    assert(security.transport.send (env_2d))

    -- message 2S: receive peer ECC-DH pubkey and ciphered K, check signature
    local env_2s = assert(security.receive())
    local hmac = assert(security.getauthentication(security.authentication, IDX_PROVIS_KS))
    local expected = hmac :update(env_2s.payload) :update(salt_device) :digest(true)
    assert (expected == env_2s.footer.autoreg_mac)
    local env_2s_inner = awtda_deserialize(env_2s.payload)
    local pubkey_server = env_2s_inner.autoreg_pubkey
    local ctext = env_2s_inner.autoreg_ctext

    -- decipher K, compute KS and KD, put in store
    local secret = ecdh.getsecret(privkey_device, pubkey_server)
    local secret_md5 = hash.new 'md5' :update (secret) :digest(true)
    local K  = xor_string(secret_md5, ctext)
    local KS = hash.new 'md5' :update (M.serverid) :update (K) :digest(true)
    local KD = hash.new 'md5' :update (M.deviceid) :update (K) :digest(true)
    assert(cipher.write(3, { K, KS, KD }))
    
    -- message 3D: acknowledge success
    local env_3d_inner = empty_envelope{status=200}
    local filter_3d, footer_3d = signer(salt_server)
    local env_3d_outer = awtda.envelope({ id=M.deviceid },footer_3d)
    local env_3d = ltn12.source.chain(env_3d_inner, filter_3d, env_3d_outer)
    assert(security.transport.send (env_3d))

    return 'ok'
end

return M
