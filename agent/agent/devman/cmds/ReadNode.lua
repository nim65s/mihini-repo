-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Cuero Bugot        for Sierra Wireless - initial API and implementation
--     Fabien Fleutot     for Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

local dev      = require 'agent.devman'
local tm       = require 'agent.treemgr'
local srvcon   = require 'agent.srvcon'
local airvantage   = require 'racon'
local upath    = require 'utils.path'
local niltoken = require 'niltoken'

local POLICY = 'now'

-- Send data recursively. The point of not reifying the table with
-- `agent.treemgr.table` is that the whole node might not fit in RAM.
-- However, it tries to send everything with the same path in a single
-- record, to limit sdb table creations.
local function recsend(path)
    local value, children = tm.get(path)
    if not children then 
        assert(dev.asset :pushdata (path, niltoken(value), POLICY))
    elseif type(children)=='table' then
        local record = { }
        for _, child_path in ipairs(children) do
            local value, children = tm.get(child_path)
            if not children then 
                local _, leaf=upath.split(child_path, -1)
                record[leaf]=value -- group same-path items together
            else recsend(child_path) end
        end
        if next(record) then
            assert(dev.asset :pushdata (path, record, POLICY))
        end
    else error(children) end -- children is actually an error msg
end

local function ReadNode(sys_asset, paths)
	log('XXX', 'WARNING', "Executing Readnode(@sys, %s)", sprint(paths))
	for _, path in pairs(paths) do recsend(path) end
    return "ok"
end

return ReadNode