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
local md5_new = require "crypto.md5"
local lfs = require "lfs"
local ltn12 = require "ltn12"
local http = require "socket.http"
local string = require "string"
local config = require"agent.config"
local log = require"log"
local sched = require"sched"
local timer = require"timer"
--this time function is not affected by date adjustment, perfect for periodic action
local monotonic_time = require 'sched.timer.core'.time
local data = common.data

local M = {}


local start_m3da_download
local init_m3da_download

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
--  otherwise, we return nil and the mode is set to write from beginning
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

--internal function used in start_m3da_download
--don't use state.stepfinished here, return error and deal with it in start_m3da_download
local function do_m3da_download(dwlstate, headers, hrange)

        -- Following functions are used to send download progress to user during the download
        local periodictask, err
        local needtostop = false
        local lasttimenotif = 0
        dwlstate.storedsize = dwlstate.storedsize or 0

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

            local currenttime = monotonic_time()
            --if download progress was sent not long ago, discard current notification
            if currenttime - lasttimenotif < (config.update.dwlnotifperiod or 2) then
                return
            end
            lasttimenotif = currenttime

            local details
            if headers and headers.contentlength then details = string.format("stored=%d%%", (dwlstate.storedsize*100/headers.contentlength))
            else details = string.format("stored_size=%d bytes", dwlstate.storedsize)
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
                return nil
            elseif chunk == "" then
                return ""
            else
                dwlstate.storedsize = dwlstate.storedsize + #chunk
                -- chunk is not changed, returned it as it for md5!
                return chunk
            end
        end

        --start a periodic task that will run the download notifier
        --this ensures that in case of not data is received (but socket is not closed) for a long time,
        -- download progress notification will be sent anyway
        periodictask,err = timer.periodic(config.update.dwlnotifperiod or 2, downloadnotifier)
        if not periodictask then log("UPDATE", "WARNING", "Can't start periodic task to send download progress, err=%s", tostring(err)) end

        --actually start the download
        local body, statuscode, headers, statusline = http.request{
            url = data.currentupdate.infos.url,
            sink =  ltn12.sink.chain( ltn12.filter.chain(myfilter, dwlstate.md5filter), ltn12.sink.file(io.open(dwlstate.updatepath, dwlstate.mode))),
            method = "GET",
            headers = hrange,
            step = ltn12.pump.step,
            proxy = config.server.proxy
        }
        --if the download was interrupted (user request received while using state.stepprogress),
        -- then just quit, don't use state.stepfinished, correct update state is set by state.stepprogress
        if needtostop then log("UPDATE", "WARNING", "download: http request aborted") return "interrupted" end
        log("UPDATE", "DETAIL", "download: http request done")
        -- if we got here then http request went to its end, clean download stuff: kill periodictask.
        downloadfinalizer()

        --body = 1 if request was ok (actual body is in sink),
        -- nil,err if error occurred
        if not body then return nil, statuscode end

        return "ok", { statuscode=statuscode, headers=headers, statusline=statusline}
end


--M3DA download state vars:
--table with values to wait before trying again the package download
-- each delay is used 1 time, number of values in the table determine the number of dwl retries.
-- in seconds, meaning 1 minute, 30 minutes, 1 hour
local m3da_dwl_retry_delays ={ 60, 30*60, 60*60 }

local m3da_dwl_retry_state

-- the point of this function is just to init m3da_dwl_retry_state table:
-- - this table must be reinit at each new update
-- - this table must be reinit after each pause/resume or reboot/resume 'event' so it must not be persisted
-- so:
-- - init_m3da_download is set at m3da procotol step start
-- - start_m3da_download is used for m3da download retries
function init_m3da_download()


   m3da_dwl_retry_state = {-- not persisted table, retries are reset on update state resume
        attempt = 0,          -- initialized at 0, max values is  #retry_delays, meaning download number of retries is #retry_delays
        resume_error = false  -- indicate whether the download seemed to fail because of resume request
        }

    start_m3da_download()
end

function start_m3da_download()
    log("UPDATE", "INFO", "Start download using M3DA command info")

    if not data.currentupdate.infos.url or "string" ~= type(data.currentupdate.infos.url)
    or not data.currentupdate.infos.signature or "string" ~= type(data.currentupdate.infos.signature) then
        return state.stepfinished("failure", 554, "Download failure: Bad update informations")
    end

    --we get free space
    local freespace, err = common.getfreespace(common.tmpdir)
    if not freespace then
        return state.stepfinished("failure", 501, string.format("Download failure: Cannot get free space on device: %s", tostring(err)))
    end

    --we check the existing package to get the size and the mode.
    local pkgname = string.match(data.currentupdate.infos.url, ".+/(.+)$")
    local updatepath = common.tmpdir.."/package_" .. (pkgname or "M3DA")..".tar"
    local sz, mode = existingfile(updatepath)

    -- save update file name so that it can be cleaned in case of error
    data.currentupdate.updatefile=updatepath
    common.savecurrentupdate()

    local md5 = md5_new()
    local md5filter = md5:filter()

    --we get the headers of package
    local headers = getheaderspackage(data.currentupdate.infos.url)

    --if the package is existing, we check if the package is already completed,
    --otherwise we try to resume the download provided that the server accepts the request "Range"

    local hrange --hrange is left to nil when no download resume is requested
    local exphcontentrange --contains expected content-range to be sent as response to range request

    local need_download = true
    if sz and sz > 0 then
        if headers and headers.contentlength and sz == headers.contentlength then
            log("UPDATE", "INFO", "Download: file is already completed :)")
            md5 = compute_md5(md5, updatepath)
            need_download = false
        elseif headers and headers.acceptrange and headers.contentlength then
            log("UPDATE", "INFO", "Download: found package with size " ..sz .. ", trying to resume download...")
            --prepare HTTP header with range as server supports it.
            hrange = { ["Range"] = "bytes=" .. sz .."-" }
            --to compare with the header that will be sent by the Get response:
            exphcontentrange = string.format("bytes %d-%d/%d", sz, headers.contentlength, headers.contentlength)
            --update md5 context with current data
            md5 = compute_md5(md5, updatepath)
        else
            log("UPDATE", "INFO", "Download: download resume not supported by server, starting from scratch")
            sz = 0
            mode = "w+"
        end
    else
        sz = 0
        log("UPDATE", "INFO", "Download: download from scratch")
    end


    --download package
    if need_download then

        if headers and headers.contentlength and freespace < (headers.contentlength - sz)  then
            return state.stepfinished("failure", 555, "Download failure: Not enough free space to download package")
        end

        --cancel resume when previous attempt failure was due to resume issue (the download will start from the beginning)
        if hrange and m3da_dwl_retry_state.resume_error then
            log("UPDATE", "INFO", "Download: download resume cancelled due to previous download errors, starting from scratch")
            hrange = nil
            sz=0
        end

        local result, result_http = do_m3da_download({storedsize=sz, md5filter=md5filter, mode = mode, updatepath = updatepath}, headers, hrange)

        local need_retry=false

        if result == "interrupted" then
            --download was interrupted by a update request (pause/abort) from user, stop here
            return
        elseif result == "ok" then
            log("UPDATE", "DETAIL", "Analyzing http results")
            if type(result_http.statuscode) ~= "number" then
                log("UPDATE", "WARNING", "Download: unexpected status: %s", tostring(result_http.statuscode))
                need_retry=true
            elseif result_http.statuscode == 206 and result_http.headers and result_http.headers["Content-Range"]~= exphcontentrange then
                --we didn't get the expected range
                --maybe we could do another resume afterwards?
                --for now we treat this as unsupported resume answer
                log("UPDATE", "WARNING", "Download: resuming download failed: unexpected Content-Range: %s", tostring(result_http.headers["Content-Range"]))
                m3da_dwl_retry_state.resume_error = true
                need_retry=true
            elseif result_http.statuscode == 200 and hrange then
                -- this one is quite tricky: we ask for a resume, but got 200 instead of 206 status
                -- very likely the server sent us the whole file again and we concatenated it with previous part
                -- maybe we could check resulting file size and skip duplicated data
                -- for now we treat this as unsupported resume answer
                log("UPDATE", "WARNING", "Download: unexpected 200 status after resumed requested, refusing data")
                m3da_dwl_retry_state.resume_error = true
                need_retry=true
            elseif result_http.statuscode>=200 and result_http.statuscode < 300 then
               log("UPDATE", "DETAIL", "Download: status code indicates success %s", tostring(result_http.statuscode))
            elseif result_http.statuscode == 416 then
               --HTTP 416: Requested Range Not Satisfiable
               log("UPDATE", "WARNING", "Download: Requested Range Not Satisfiable");
               m3da_dwl_retry_state.resume_error = true
               need_retry=true
            else
                log("UPDATE", "WARNING", "Download: failed with unsupported result_http.statuscode %s", tostring(result_http.statuscode) )
                need_retry=true
            end

        else
            log("UPDATE", "WARNING", "download failed: (%s)", tostring(result_http))
            need_retry = true
        end

        if need_retry then
            if m3da_dwl_retry_state.attempt >= #m3da_dwl_retry_delays then
                return state.stepfinished("failure", 552, string.format("Download failed: all retries exhausted"))
            else
                m3da_dwl_retry_state.attempt =  m3da_dwl_retry_state.attempt +1

                local function dwlretrynotifier()
                    local function dwlretryfinalizer()
                        sched.signal("update.dwlretry", "interrupted")
                    end
                   --dwlretryfinalizer is called in/by stepprogress only if download is paused/aborted.
                    state.stepprogress("Waiting for download retry", dwlretryfinalizer)
                end

                --start poller to listen to download request that may be sent while waiting for next retry
                local periodictask,err = timer.periodic(config.update.dwlnotifperiod or 2, dwlretrynotifier)
                if not periodictask then log("UPDATE", "WARNING", "Can't start periodic task to send download retry, err=%s", tostring(err)) end

                log("UPDATE", "INFO", "Download: waiting for next retry: %d seconds", m3da_dwl_retry_delays[m3da_dwl_retry_state.attempt])
                local event = sched.wait("update.dwlretry", {"*", m3da_dwl_retry_delays[m3da_dwl_retry_state.attempt]} )
                --ensure timer is cleaned, stopped.
                timer.cancel(periodictask)
                periodictask = nil

                --download retry phase was interrupted by a update request (pause/abort) from user, stop here
                if event == "interrupted" then return end
                --otherwise restart the download
                sched.run(start_m3da_download)
                return
            end
        end

        --
        --retries management
        --

        end -- : downloading is not needed anymore


        local hex_checksum = md5:digest(false)
        data.currentupdate.infos.signature = string.lower(data.currentupdate.infos.signature)

        if hex_checksum ~= data.currentupdate.infos.signature then
            return state.stepfinished("failure", 553, "Download: signature mismatch for update archive")
        end

        --everything went ok, go to next update step
        return state.stepfinished("success")


end


local download_actions =  {
    localupdate=start_localupdate_download,
    m3da=init_m3da_download
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
        return state.stepfinished("failure", 556, "download failed, invalid update")
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

