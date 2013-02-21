-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Laurent Barthelemy for Sierra Wireless - initial API and implementation
--     Minh Giang         for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local common = require"agent.update.common"
local io = require "io"
local hash = require "crypto.hash"
local lfs = require "lfs"
local ltn12 = require "ltn12"
local http = require "socket.http"
local string = require "string"
local config = require"agent.config"
local log = require"log"
local sched = require"sched"
local timer = require"timer"
local data = common.data

local M = {}


local start_awt_download

-- state mgmt function to be given at init:
local state = {}
--state.stepfinished
--state.stepprogress

local function start_localupdate_download()
    log("UPDATE", "DETAIL", "start_localupdate_download: almost nothing to do :)")
    --TODO check file stuff.
    data.currentupdate.updatefile = data.currentupdate.infos.updatefile
    data.currentupdate.infos.updatefile = nil
    --no need to save current update, stepfinished will do it for us
    return state.stepfinished("success")
end

--Get the headers of package
local function getheaderspackage(currenturl)
    local headers = {}
    local r, c, h = http.request { method = "HEAD", url = currenturl }
    if r~=1 or c~=200 then
        log("UPDATE", "WARNING", "Download: Cannot get the headers of package")
        return nil
    end
    headers.contentlength = tonumber(h["content-length"])
    if h["accept-ranges"] == "bytes" then
        headers.acceptrange = true
    else
        headers.acceptrange = false
    end
    return headers
end

--check existing package, if the package exists,
--  then we get the size of file and the mode is set to append,
--  otherwise, we return nil and the mode is set to write from begining
local function existingfile(filename)
    local sz = lfs.attributes(filename, "size")  --get size of file
    local mode = {}
    if sz then
        mode = "a+"  --append mode
        return sz, mode
    else
        mode = "w+"   --write mode
        return nil, mode
    end
end

--compute md5 from an existing file
--use empty md5 context created outside
local function compute_md5 (md5, file)
    local size = 2048
    local f = io.open(file, "r")
    local read = f:read(size)
    while read do
        md5:update(read)
        read = f:read(size)
    end
    f:close(file)
    return md5
end

function start_awt_download()

    if not data.currentupdate.infos.url or "string" ~= type(data.currentupdate.infos.url)
    or not  data.currentupdate.infos.signature or "string" ~= type(data.currentupdate.infos.signature) then
        return state.stepfinished("failure", 554, "Download failure: Bad update informations")
    end

    --we get free space
    local freespace, err = common.getfreespace(common.tmpdir)
    if not freespace then
        return state.stepfinished("failure", 501, "Download failure: can't get free space on device: %s", err)
    end

    --we check the existing package to get the size and the mode.
    local pkgname = string.match(data.currentupdate.infos.url, ".+/(.+)$")
    local updatepath = common.tmpdir.."/package_" .. (pkgname or "AWTDA")..".tar"
    local sz, mode = existingfile(updatepath)

    -- save update file name so that it can be cleaned in case of error
    data.currentupdate.updatefile=updatepath
    common.savecurrentupdate()

    local md5 = hash.new("md5")
    local md5filter = md5:filter()

    --we get the headers of package
    local headers = getheaderspackage(data.currentupdate.infos.url)

    --if the package is existing, we check if the package is already completed,
    --otherwise we try to resume the download provided that the server accepts the request "Range"
    local b, c, h, s, hrange
    local download = true
    if sz and sz > 0 then
        if headers and sz == headers.contentlength then
            log("UPDATE", "INFO", "Download: file is already completed :)")
            md5 = compute_md5(md5, updatepath)
            download = false
        elseif headers and headers.acceptrange then
            log("UPDATE", "INFO", "Download: found package with size " ..sz .. ", trying to resume download...")
            --prepare HTTP header with range as server supports it.
            hrange = { ["Range"] = "bytes=" .. sz .."-" }
            md5 = compute_md5(md5, updatepath)
        else
            log("UPDATE", "INFO", "Download: download resume not supported by server, starting from scratch")
            sz = 0
            mode = "w+"
        end
    else sz = 0 end

    --download package
    if download then
        if headers and freespace < (headers.contentlength - sz)  then
            return state.stepfinished("failure", 555, "Download failure: Not enough free space to download package")
        end

        -- Following functions are used to send download progress to user during the download

        local periodictask
        local storedsize = sz
        local needtostop = false
        local lasttimenotif = 0

        --this function will be called at the end of the download: either regular download or because of a pause/abort request
        local function downloadfinalizer()
            needtostop=true
            if periodictask then
                timer.cancel(periodictask)
                periodictask = nil
            end
        end

        --this function will be executed periodically send to download progress to users
        local function downloadnotifier()
            if not data.currentupdate then
                log("UPDATE", "DETAIL", "download: periodicnotifier: kill self")
                timer.cancel(periodictask)
                periodictask = nil
            end

            local currenttime=os.time()
            --
            if currenttime - lasttimenotif < (config.update.dwlnotifperiod or 2) then
                return
            end
            lasttimenotif = currenttime

            local details
            if headers and headers.contentlength then details = string.format("stored=%d%%", (storedsize*100/headers.contentlength))
            else details = string.format("stored_size=%d bytes", storedsize)
            end

            -- send the download progress to the registered user
            -- if a download request is received and needs to stop this download,
            -- then the download finalizer will be called
            state.stepprogress(details, downloadfinalizer)
        end

        --filter that just passes the data it receives, keeping the size of the received data so far
        local function myfilter(chunk)
            --calling notifier in filter ensures that specific case where download is so fast (local download)
            --that the periodic task is never given a chance to run doesn't lead to no download progress sent
            -- (we are sure myfilter is called as long as data are received)
            downloadnotifier()

            --return nil to stop the download
            if chunk == nil or needtostop then
                 log("UPDATE", "DETAIL", "myfilter: end")
                return nil
            elseif chunk == "" then
                return ""
            else
                storedsize = storedsize + #chunk
                -- chunk is not changed, returned it as it for md5!
                return chunk
            end
        end

        --start a periodic task that will run the download notifier
        --this ensures that in case of not data is received (but socket is not closed) for a long time,
        -- download progress notification will be sent anyway
        periodictask,err = timer.periodic(config.update.dwlnotifperiod or 2, downloadnotifier)
        if not periodictask then log("UPDATE", "WARNING", "Can't start periodic task to send download progress, err=%s", tostring(err)) end

        b, c, h, s = http.request{
            url = data.currentupdate.infos.url,
            sink =  ltn12.sink.chain( ltn12.filter.chain(myfilter, md5filter), ltn12.sink.file(io.open(updatepath, mode))),
            method = "GET",
            headers = hrange,
            step = ltn12.pump.step,
            proxy = config.server.proxy
        }
        --if the download was interrupted (user request received while using state.stepprogress),
        -- then just quit, don't use state.stepfinished, correct update state is set by state.stepprogress
        if needtostop then return end
        log("UPDATE", "DETAIL", "download: http request done")
        -- if we got here then download went to its end, clean download stuff: kill periodictask.
        downloadfinalizer()

        --if download fails, the update file will be cleaned by regular clean up at update finish state
        if not b or (type(c)=='number' and (c<200 or c>=300)) then
            c =  b and s or c -- set the error string to either the real error string or the status line if no network error happened...
            return state.stepfinished("failure", 552, string.format("Download: Error while doing http request, error: %s", c))
        end
    end

    local checksum = md5:digest()

    --lower the character chain before comparison
    checksum = string.lower(checksum)
    data.currentupdate.infos.signature = string.lower(data.currentupdate.infos.signature)

    if checksum ~= data.currentupdate.infos.signature then
        return state.stepfinished("failure", 553, "Download: Signature mismatch for update archive")
    end
    
    --everything went ok, go to next update step
    return state.stepfinished("success")
end


local download_actions =  {
    localupdate=start_localupdate_download,
    awtda=start_awt_download
}

local function finish()
    log("UPDATE", "DETAIL", "download finish: nothing to do :)")
    state.stepfinished("success")
end

local function start()
    --check current status
    if not data.currentupdate then
        log("UPDATE", "ERROR", "Downloader start failed: no current update!")
        return
    end
    if not data.currentupdate.infos or not data.currentupdate.infos.proto then
        log("UPDATE", "ERROR", "Downloader start failed: invalid current update!")
        return state.stepfinished("failure", 556, "download failed, invalid current update")
    end

    --use protocol specific actions
    if not download_actions[data.currentupdate.infos.proto] then
        log("UPDATE", "ERROR", "Downloader start failed: unsupported protocol '%s'", tostring(data.currentupdate.infos.proto));
        return state.stepfinished("failure", 557, "download failed, unsupported protocol")
    end

    --actually start download
    --each protocol action is responsible for resume capabilities
    download_actions[data.currentupdate.infos.proto]()
end


local function init(step_api)
    state = step_api
    return "ok"
end



M.start = start
M.finish = finish
M.init = init

return M