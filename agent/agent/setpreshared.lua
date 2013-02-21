local security = require 'agent.srvcon.session.security'
local cipher   = require 'crypto.cipher'
local hash     = require 'crypto.hash'

local function x(s)
    log('AGENT-SETPRESHAREDKEY', 'WARNING', "%s", s)
    print(s)
end

local function k2s(str)
    local bytes = { str :byte(1, -1) }
    for i, k in ipairs(bytes) do bytes[i] = string.format("%02x", k) end
    return table.concat(bytes, ' ')
end

function setpreshared(K)
    checks('string')
    x("Setting pre-shared key")
    assert(os.execute('mkdir -p crypto'), "Can't create crypto folder")
    local serverid = assert(agent.config.server.serverId, "Missing server.serverId in config")
    local deviceid = assert(agent.config.agent.deviceId, "Missing agent.deviceId in config")
    local KS = hash.new 'md5' :update (serverid) :update (K) :digest(true)
    x("KS="..k2s(KS))
    local KD = hash.new 'md5' :update (deviceid) :update (K) :digest(true)
    x("KD="..k2s(KD))
    assert(security.IDX_PROVIS_KD == security.IDX_PROVIS_KS + 1)
    assert(cipher.write(security.IDX_PROVIS_KS, { KS, KD }))
    x("Keys written in store")
end

return setpreshared