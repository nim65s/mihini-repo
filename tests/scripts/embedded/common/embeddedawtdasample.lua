-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

require 'sched'
require 'strict'
require 'awtdahl'

-- process received messages
function recv(asset, m)
    local messageType, path, content, needToAck = awtdahl.parsemessage(m)

    -- process the message
    print(path)
    if (messageType == "Command") then
        print("Command:", content.command)
        print(content.args)
    elseif (messageType == "TimestampedData") then
        print("TimestampedData:", content)
    elseif (messageType == "CorrelatedData") then
        print("CorrelatedData:", content)
    end

    -- return ack if necessary
    if needToAck then
        asset:sendacknowledgement(m)
        asset.com:connecttoserver()
    end
end


function ackhandler(path, statusCode, data)
   print(path, statusCode, data)
end

function awtdarunsample()
    -- init asset
    local assetId = "house"
    print("Initialize Asset")
    local assethouse = awtdahl.newasset(assetId)
    -- register recv function for asset
    local hook = sched.sighook(assethouse, "Message", function(ev, m) sched.run(recv, assethouse, m) end)
    print("Start Asset")
    -- start asset
    assethouse:start()

    local values, events
    local now = os.time()
    -- add room data
    print("Send TimestampedData: bedroom")
    values = { preset_temperature = {timestamp = now, data = 19 } }
    assethouse:sendtimestampeddata("bedroom", values, ackhandler)

    -- add room event
    print("Send Event: bedroom")
    events = { {timestamp = now+60, code = 105, data = "Temperature too hot"} }
    assethouse:sendevents("bedroom", events, ackhandler)

    -- add livingroom data
    print("Send TimestampedData: living-room")
    values = { temperature = {start = now, period = 5*60, data = {16, 17, 18, 17, 19} } }
    assethouse:sendtimestampeddata("living-room", values, ackhandler)

    -- add livingroom event
    print("Send Event: living-room")
    events = { {timestamp = now, code = 106, data = "Window opened"} }
    assethouse:sendevents("living-room", events, ackhandler)

    print("Connect to server")
    assethouse.com:connecttoserver()

    print("Wait for server response")
    sched.wait(10) -- wait 10 seconds to let the server process some of the responses, if any
    --print("Connect to server")
    --assethouse.com:connecttoserver()
    --sched.wait(10) -- take some time to process the responses, if any

    -- stop asset
    print("Stop Asset")
    assethouse:stop()
    sched.kill(hook)

    return 1
end

--sched.run(runsample)


-- comment the following line if running in the same VM than the agent because the scheduler is already running
--sched.loop() -- start the scheduler

