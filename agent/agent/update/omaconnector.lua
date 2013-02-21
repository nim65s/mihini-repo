-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local omadm_core --call to require "omadmClient" will be done if omadm is needed
local sched = require"sched"
local config = require"agent.config"
local common = require"agent.update.common"
local notifynewupdate --to be passed at init call
local data = common.data

--IPC communication param

--ID to listen to receive msg from OMADM client
local LISTEN_ID_OMADM = "OmaDM"
--ID to write message to OMADM client
local WRITE_ID = "UpdateAgent"

-- CMD between OMADM client and UPDATEAGENT

-- From OMA DM
local ODM_NEW_UPDATE = "OMADM_NEW_UPDATE_AVAILABLE"
local ODM_INIT_DONE = "OMADM_INIT_DONE"
local ODM_ACTION_END = "OMADM_ACTION_END"

-- To OMA DM
local AGT_RUN = "AGENT_REQUEST_DM_SESSION"
local AGT_UPT_RES = "AGENT_UPDATE_RESULT"
local AGT_SMS_FROM_SRV = "AGENT_SMS_FROM_SERVER"
local AGT_SEND_FWV = "AGENT_SEND_FWV"
local AGT_SEND_SWV = "AGENT_SEND_SWV"

local M = {}

local omasendresult

--omadmClient_trg init can be done only 1 time!
--protect it!
INIT_DONE = nil

--retry management of network errors
-- TODO check if internalrun is needed
local function runsession(type, args)
    if not type then type = AGT_RUN end --default session is generic session.
    local function internalrun()
        --set flag
        data.swlist.status = 1
        saveswlist()
        sendinfos()
        -- request session start
        sched.signal(WRITE_ID, type, args)
        --wait for session end
        local _, status  = sched.wait(LISTEN_ID_OMADM, ODM_ACTION_END);
        -- remove flag
        data.swlist.status = 0
        saveswlist()

        if status and status == "0" then
            log("UPDATE", "INFO", "OMADM action ended successfully with code [0x%x]",tonumber(status))
        else
            log("UPDATE", "ERROR","OMADM action error with code [0x%x]",tonumber(status) or "-1")
        end
        -- manual filter (not very clean...) of network errors to trigger retries on netman events.
        if status and status == "2308" or status == "2304" then return nil, "Network error" end

        return 1, status
    end

    local nmres,res,status = base.tryaction(internalrun)

    if not nmres then
        log("UPDATE", "INFO", "OMADM action will be resumed when network will be up again")
        sched.wait("NETMAN", "CONNECTED", 300)
        --last try!
        log("UPDATE", "INFO", "OMADM action: last try after network issues");
        fct();
    end
    return res
end

local function rundefaultsession()
    return runsession(AGT_RUN)
end

-- process OMADM SMS comming from WAP PUSH port
local function processSMS(sms)
    log("UPDATE", "INFO", "Incoming DM SMS ...", string.len(sms.message) )
    runsession(AGT_SMS_FROM_SRV, sms.message)
end


--function that process evt comming from omadm client
local function process_omadm_msg(cmd, ...)
    local params = {...}
    local res,err

    if not cmd or type(cmd) ~= "string" then
        log("UPDATE", "ERROR", "Unknown OmaDM event")
        return
    end

    if cmd == ODM_NEW_UPDATE then
        log("UPDATE", "INFO", "OMADM client has new update")
        local updatefile = params[1]
        -- store useful information about the new update ( for clean up for instance )
        local newupdate = {updatefile = updatefile, infos={proto= "OMADM"}}
        local res, errcode, errstr =  notifynewupdate(newupdate)
        if not res then --update was rejected
            --another update can be in progress, then we need to be sure the current one wont be aborted because of
            --this new one, so we use the oma send result function to be sure not to mess with potential current update
            omasendresult(errcode, errstr)
        end
    end
end

--sighook function to forward event process
local function read_fct(cmd, ...)
    -- stop msg ?
    if "DESTROY" == cmd then return nil end
    sched.run( process_omadm_msg, cmd, ...)
    return "again"
end

-- send update result to the server using omadm stack
function omasendresult(resultcode, err_str)
    log("UPDATE", "INFO", "Sending update result to OMADM server")
    --send update result to oma stack
    sched.signal(WRITE_ID, AGT_UPT_RES, resultcode)
    --request dm session to finish fumo job
    run_session()
end

local function sendinfos()
    --send DM session info
    sched.signal(WRITE_ID, AGT_SEND_FWV, data.swlist.version or "unknown")
    sched.signal(WRITE_ID, AGT_SEND_SWV, data.swlist.version or "unknown")
end



--helper function to start an oma dm session
local function rundmsession()
    if config.update.omadm then
        log("UPDATE", "DETAIL", "OMADM session requested")
        return oma.runsession()
    else return nil, "OMADM client not activated in config"   end
end



local function init(globalnotifynewupdate)
    omadm_core = require "omadmclient"
    notifynewupdate = globalnotifynewupdate

    -- C stuff for omadm
    -- just call C init function with config params
    local res, err = omadm_core.start(config.agent.signalport ,config.agent.deviceId)
    if not res then
        --cancel sighook
        sched.signal(LISTEN_ID_OMADM, "DESTROY")
        return nil, "Update service cannot init omadm client ["..err.."]"
    end

    -- Register for SMS
    local function newsms(_, sms)
        log("UPDATE", "INFO", "SMS = %s", sprint(sms))
        if sms.ports and sms.ports.dst == 2948 then
            sched.run(processSMS, sms)
        end
    end
    if config.modem.sms then sched.sighook("messaging", "sms", newsms) end

    -- wait for init to be done
    sched.wait(LISTEN_ID_OMADM, ODM_INIT_DONE)

    -- when init is done, register msg listener on OmaDM signals
    sched.sighook(LISTEN_ID_OMADM, {ODM_NEW_UPDATE}, read_fct)

    -- init infos (soft version)
    sendinfos()

    --check if a oma dm session was interupted by a reset.
    if not data.swlist.status then
        data.swlist.status = 0;
        common.saveswlist()
    elseif 1 == data.swlist.status then
        log("UPDATE", "INFO", "DM action was interrupted, trying a new DM session")
        sched.run(rundmsession)
    end

    return "ok"
end

M.init = init
M.sendresult = omasendresult
M.runsession = rundefaultsession

return M;
