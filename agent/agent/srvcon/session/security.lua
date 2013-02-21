-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Gilles Cannenterre for Sierra Wireless - initial API and implementation
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local log     = require "log"
local ltn12   = require "ltn12"
local persist = require "persist"
local awtda   = require 'bysant.awtda'
local awtda_deserialize = awtda.deserializer()

local cipher = require "crypto.cipher"
local hmac   = require "crypto.hmac"
local hash   = require "crypto.hash"
local rng    = require "crypto.rng"

local M = setmetatable({ }, { __type='srvcon.session' })

-------------------------------------------------------------------------------
-- Indexes of cryptographic keys
M.IDX_PROVIS_KS  = 1 -- server provisionning key
M.IDX_PROVIS_KD  = 2 -- device provisionning key
M.IDX_CRYPTO_K   = 3 -- encryption/decryption key
M.IDX_AUTH_KS    = 4 -- server authentication key
M.IDX_AUTH_KD    = 5 -- device authentication key

-------------------------------------------------------------------------------
-- True iff we're waiting for a response to a request. If not, then any incoming
-- message is to be treated as unsollicited: it still needs to be authenticated
-- and decrypted and sent to `srvcon`, but it won't be used as an acknowledgement
-- to the previous request.
--
M.waitingresponse = false

-------------------------------------------------------------------------------
-- Generates a new random nonce, used as a salt in all authentications and
-- encryptions to prevent replay attacks.
--
-- @return a new random nonce
--
function M.getnonce()
    if not M.noncegenerator then M.noncegenerator = rng.new() end
    return M.noncegenerator:read(16, true)
end

-------------------------------------------------------------------------------
-- Save an error status before causing an error.
-- This is intended to be call in `M.unprotectedsend()`, directly or indirectly, and the
-- error to be caught in `M.send`. Thanks the the error status number, an
-- error message can be sent to the peer.
--
-- @param status an AWTDA status, to be sent to the perr
-- @param msg a string error message to display in local logs
-- @return never returns
--
local function failwith(status, msg)
    checks('number|string', 'string')
    M.last_status = status
    error(msg)
end

-------------------------------------------------------------------------------
-- Returns an authentication object + corresponding LTN12 filter.
-- Data must go either through the filter or the object's `:update(data)`
-- method; the resulting hash can be retrieved with the object's `:digest(bool)`.
--
-- @param authid an authentication scheme, `'<methodname>-<hashname>'`.
-- @param keyidx an index in the keys table.
-- @return an authentication object instance, an LTN12 filter.
--
function M.getauthentication(authid, keyidx)
    checks('string', 'number')
    local method, hash = string.match(authid, "^(.+)%-(.+)$")
    if not method or not hash then failwith(400, 'bad auth scheme') end
    local obj = assert(hmac.new{name = hash, keyidx = keyidx})
    return obj, obj :filter()
end

-------------------------------------------------------------------------------
-- Returns an encryption object + corresponding LTN12 filter.
-- The object has a ':process()' method which takes an encrypted string
-- and returns a decrypted one.
--
-- @param enchid an encryption scheme, `'<methodname>-<hashname>-<keysize>'`
-- @param mode either `"enc"` or `"dec"`.
-- @param nonce the current nonce.
-- @return an authentication object instance, an LTN12 filter.
--
local function getencryption(encid, mode, nonce)
    checks('string', 'string', 'string')
    local method, chain, keysize = assert(string.match(encid, "(.+)%-(.+)%-(%d+)"))
    assert (method and chain and keysize, "failed to parse encryption scheme")
    local obj, err = cipher.new({ -- cipher cfg
        name    = method,
        mode    = mode,
        nonce   = nonce,
        keyidx = M.IDX_CRYPTO_K,
        keysize = keysize/8
    }, { -- chaining cfg
        name = chain,
        iv   = hash.digest("md5", nonce, true)
    })
    return obj, obj:filter({name = (chain == "cbc") and "pkcs5" or "none"})
end

-------------------------------------------------------------------------------
-- Signs, encrypts and sends a message through the transport layer.
-- Will cause an error if anything goes wrong.
--
-- @param msg_src an LTN12 source producing the message's serialized stream
-- @param current_nonce the nonce to be used for encryption+authentication
-- @param next_nonce the nonce to be used next time, and to be sent to the peer.
--
function M.sendmsg(msg_src, current_nonce, next_nonce)
    checks('function', 'string', 'string')
    log('SRVCON-SESSION', 'DEBUG', "Sending an authenticated%smessage",
        M.encryption and " and encrypted " or " ")

    local inner_envelope = awtda.envelope{ nonce=next_nonce, status=200 }

    -- Authentication envelope.
    -- Authentication filter will transparently compute the mac of everything
    -- that went through it. auth_handler allows to retrieve that hash.
    -- The footer of the envelope is wrapped in a closure, so that the mac
    -- is only computed after all data went through.
    local auth_handler, auth_filter = M.getauthentication(M.authentication, M.IDX_AUTH_KD)
    
    local original_auth_filter = auth_filter
    auth_filter = function(data)
        print("Signing", sprint(data))
        return original_auth_filter(data)
    end
    
    local auth_envelope = awtda.envelope(
        { id=M.deviceid, auth=M.authentication, cipher=M.encryption },
        function() auth_filter(current_nonce); return { mac = auth_handler :digest (true) } end)

    local envelopes -- All envelopes and filters: auth envelope, optional ciphering, private envelope

    -- Encryption filter.
    -- If an encryption method is specified, then the content of the payload
    -- must go through a cipher filter to be scrambled. This filter is added
    if M.encryption then
        local cipher_handler, cipher_filter = getencryption(M.encryption, "enc", current_nonce)
        envelopes = ltn12.filter.chain(inner_envelope, cipher_filter, auth_filter, auth_envelope)
    else
        envelopes = ltn12.filter.chain(inner_envelope, auth_filter, auth_envelope)
    end
    local src = ltn12.source.chain(msg_src, envelopes)
    assert(M.transport.send (src))
end

-------------------------------------------------------------------------------
-- Sends a challenge, i.e. an envelope with an empty body, the cipher/auth
-- combo expected by us, and a synchronization nonce.
--
-- @param nonce the nonce to be passed to the peer, and used in the challenge's
--   response.
--
function M.sendchallenge(nonce)
    checks('string')

    log('SRVCON-SESSION', 'DEBUG', "Sending an authentication challenge")

    local envelope = awtda.envelope {
        id        = M.deviceid,
        challenge = M.authentication,
        cipher    = M.cipher,
        nonce     = nonce,
        status    = 401 } -- TODO 450 when missing encryption?

    local src = ltn12.source.chain(ltn12.source.empty(), envelope)
    assert(M.transport.send(src))
end

-------------------------------------------------------------------------------
-- Waits for a complete envelope to be received from the transport layer,
-- deserialize it and return it.
--
function M.receive()
    log('SRVCON-SESSION', 'DEBUG', "Waiting for a response")
    M.waitingresponse = true
    local ev, envelope = sched.wait(M, {'*', 60})
    M.waitingresponse = false
    if      ev == 'envelope_received' then return envelope
    elseif ev == 'timeout' then failwith(408, 'reception timeout')
    elseif ev == 'reception_error' then failwith(500, envelope) -- envelope is an error msg
    else assert(false, 'internal error') end
end

-------------------------------------------------------------------------------
-- Transport sink state:
-- `pending_data` is a string which contains the beginning of an incomplete
-- envelope;
-- `partial` is the deserializer's frozen state, to be passed back at next
-- invocation to resume the parsing where it stopped due to lack of data.
--
local pending_data = ''
local partial = nil

-------------------------------------------------------------------------------
-- sink to be passed to the transport layer, to accept incoming data from the
-- server. Push a whole envelope through the `M.incoming` pipe whenever it is
-- received.
--
-- @param data a fragment of a serialized envelope.
-- @return `"ok"` to indicate that the LTN12 sink accepted `data`.
--
function M.sink(data)
    --log('SRVCON-SESSION', 'DEBUG', "Received some data")
    if not data then return 'ok' end
    pending_data = pending_data .. data
    local envelope, offset
    envelope, offset, partial = awtda_deserialize (pending_data, partial)
    if offset=='partial' then return 'ok' -- incomplete msg, retry nex time
    elseif envelope then -- got a complete envelope
        if log.musttrace('SRVCON-SESSION', 'DEBUG') then
            log('SRVCON-SESSION', 'DEBUG', "Received an %s envelope: %s",
                M.waitingresponse and "expected" or "unsollicited",
                sprint(envelope))
            if envelope.payload and not M.encryption then
                log('SRVCON-SESSION', 'DEBUG', "Envelope payload = %s",
                    sprint((awtda_deserialize(envelope.payload))))
            end
        end
        if M.waitingresponse then -- response to a request
            sched.signal(M, 'envelope_received', envelope)
        else -- unsollicited incoming message
            sched.run(M.parse, envelope)
        end
        pending_data = pending_data :sub (offset, -1)
        return 'ok'
    else sched.signal(M, 'reception_error', offset) end -- offset is an error msg
    return 'ok'
end

-------------------------------------------------------------------------------
-- Checks that the deserialized envelope `incoming` has the proper auth+cipher
-- setup in its header, and that it's properly signed.
-- Does not decrypt the payload.
--
-- @param incoming the deserialized envelope to check
-- @param nonce the current nonce for authentication and encryption
-- @return `true` or `false` depending on whether the envelope matches the
--   protocol.
--
function M.verifymsg(incoming, nonce)
    checks('table', 'string')
    local h, f = incoming.header, incoming.footer
    if h.cipher ~= M.encryption then
       log('SRVCON-SESSION', 'WARNING', "Bad cipher protocol"); return false
    end
    if h.auth   ~= M.authentication then
       log('SRVCON-SESSION', 'WARNING', "Bad authentication protocol"); return false
    end
    local auth_handle, auth_filter = assert(M.getauthentication(M.authentication, M.IDX_AUTH_KS))

    --print("Sign checking", sprint(incoming.payload))
    --print("Sign checking", sprint(nonce))

    auth_handle :update (incoming.payload)
    auth_handle :update (nonce)
    local actual_mac, expected_mac = auth_handle :digest (true), f.mac
    local accepted = actual_mac==expected_mac

    if accepted then
        log('SRVCON-SESSION', 'DEBUG', "Incoming message signature accepted")
    else
        log('SRVCON-SESSION', 'WARNING', "Incoming message signature rejected")
    end

    return accepted
end

-------------------------------------------------------------------------------
-- Decrypts a payload string according to a nonce, returns the decrypted string.
--
-- @param payload encrypted message
-- @param nonce nonce to be used for decryption
-- @return decrypted payload
--
function M.decrypt(payload, nonce)
    checks('string', 'string')
    local cipher_handle, cipher_filter = getencryption(M.encryption, "dec", nonce)
    return assert(cipher_handle :process(payload))
end


-------------------------------------------------------------------------------
-- Tries to send an unencrypted and unauthenticated error to the peer, with the
-- status code explaining the failure.
--
function M.senderror()
    local envelope = awtda.envelope{ id=M.deviceid, status=M.last_status or 500 }
    local src = ltn12.source.chain(ltn12.source.empty(), envelope)
    M.transport.send(src)
end

-------------------------------------------------------------------------------
-- Implementation of the main request/response cycle. Anything that goes
-- wrong causes an error, to be caught with a `copcall`.
--
-- The cycle consists of:
--
-- * Trying to send the message, properly signed and encrypted;
-- * Wait for the response;
-- * If the response is a challenge, resend with the challenge's nonce and
--   wait for the next response;
-- * If the response isn't properly signed and encrypted, send a challenge and
--   wait for the next response, which must then be based on the proper nonce;
-- * Broadcast the authenticated and decrypted message payload to `srvcon`;
-- * Return the nonce from the peer's latest response.
--
-- @param src_factory a function returning an LTN12 source which in turn streams
--   the serialized message to send. The factory function might be called more
--   than once.
-- @param current_nonce the nonce to be used for the first
--   encryption/authentication. Other nonces might be used, e.g. if the peer
--   responds with a challenge.
-- @return the nonce to be used next time.
--
function M.unprotectedsend(src_factory, current_nonce)
    checks('function', 'string')
    local next_nonce = M.getnonce()

    -- Send request and wait for response.
    M.sendmsg(src_factory(), current_nonce, next_nonce)
    local incoming = M.receive()

    -- If the peer isn't happy with my auth/encryption,
    -- change the nonce and resend my message.
    if incoming.header.challenge then
        log('SRVCON-SESSION', 'DEBUG', "Received a challenge, resending with new nonce")
        current_nonce = assert(incoming.header.nonce)
        M.sendmsg(src_factory(), current_nonce, next_nonce)
        incoming = M.receive()
        if incoming.header.challenge then failwith (407, 'multiple challenges') end
    end

    -- Check and dispatch the incoming message.
    return M.unprotectedparse(incoming, next_nonce, "It's a response")
end

-------------------------------------------------------------------------------
-- Reacts to an incoming message:
--
-- * rejects it with a challenge and waits for the corrected response, if the
--   message isn't acceptable because of
--   desynchronized nonces / bad protocols / bad signature;
-- * dispatches the decrypted payload;
-- * handles the nonces, the one expected for the incoming message and the
--   next one advertized to the peer.
--
-- @param outer_env the incoming (outer) envelope, deserialized. Its serialized
--   payload should be the inner envelope.
-- @param nonce the nonce which the incoming message is expected to have used.
-- @param isresponse Boolean indicating whether the message parsed is a response
--   to a message sent by us. This is necessary to decide whether we must respond
--   to the message.
-- @return the nonce to be used next time.
--
function M.unprotectedparse(outer_env, nonce, isresponse)
    checks('table', 'string')

    if not M.verifymsg(outer_env, nonce) then -- bad message, send a challenge and retry
        nonce = M.getnonce()
        M.sendchallenge(nonce)
        outer_env = M.receive()
        -- Must be right the second time: we don't want to be DoS'ed
        if not M.verifymsg(outer_env, nonce) then
            failwith("NOREPORT", "Bad response to a challenge")
        end
    end

    local payload = M.encryption 
        and M.decrypt(outer_env.payload, nonce)
        or outer_env.payload

    local inner_env = awtda_deserialize(payload)

    local payload = inner_env.payload
    if payload and #payload==0 then payload=nil end

    if payload then M.msghandler(payload)
    else log('SRVCON-SESSION', 'DEBUG', 'No payload in envelope') end

    if payload or not isresponse then
        nonce = M.getnonce()
        M.sendmsg(ltn12.source.empty(), inner_env.header.nonce, nonce)
    else nonce = inner_env.header.nonce end

    return nonce
end


-------------------------------------------------------------------------------
-- Common helper for `send` and `parse`: wrap unprotected function, which
-- might cause an erro, in a pcall, and handles the success or failure.
--
-- @param unprotected_func the function to wrap
-- @return the wrapped function
--
local function protector_factory(unprotected_func)
    return function(arg, current_nonce)
        M.last_status = false -- to be filled in case of error
        local current_nonce = persist.load("security.nonce") or M.getnonce()
        local success, next_nonce = copcall(unprotected_func, arg, current_nonce)
        if success then -- success
            persist.save("security.nonce", next_nonce)
            return 'ok'
        else
            local errmsg = tostring(next_nonce)
            log('SRVCON-SESSION', 'ERROR', "Failed with status %s: %q",
                M.last_status or 500, errmsg)
            if M.last_status ~= "NOREPORT" then M.senderror() end
            return nil, errmsg
        end
    end
end    


-------------------------------------------------------------------------------
-- Reacts to an unsollicited AWTDA message. Most of the work is done by
-- `M.unprotectedparse()`, `.parse()` is mainly here to catch and report errors.
--
-- Notice the similarities between this function and `M.send`.
--
-- @param incoming deserialized incoming (outer) envelope.
--
M.parse = protector_factory(M.unprotectedparse)


-------------------------------------------------------------------------------
-- Sends an AWTDA message, passed as an LTN12 source factory, through a security
-- session. Most of the work is done by `M.unprotectedsend()`, `.send()` is mainly here to
-- catch and report errors.
--
-- @param src_factory a function returning an LTN12 source which in turn streams
--   the serialized message to send. The factory function might be called more
--   than once.
--
M.send = protector_factory(M.unprotectedsend)


M.mandatory_keys = {
    'transport', 'msghandler', 'deviceid', 'authentication' }

M.optional_keys = {
    'encryption'
}

-------------------------------------------------------------------------------
-- Configures the session layer.
--
-- @param cfg a configuration table, with the fields listed in
-- `M.mandatory_keys` and `M.optional_keys`.
-- @return `"ok"`
-- @return nil + error msg
--
function M.init(cfg)
    for _, key in ipairs(M.mandatory_keys) do
        local val = cfg[key]
        if not val then return nil, 'missing config key '..key end
        M[key]=val
    end
    for _, key in ipairs(M.optional_keys) do M[key]=cfg[key] end
    M.transport.sink = M.sink
    if hmac.new{ name='md5', keyidx=M.IDX_AUTH_KS } then
        return 'ok'
    elseif hmac.new{ name='md5', keyidx=M.IDX_PROVIS_KS } then
        local P = require 'agent.srvcon.session.provisionning'
        return P.downloadkeys()
    else
        return nil, "Neither provisionning nor authenticating crypto keys"
    end
end

return M
