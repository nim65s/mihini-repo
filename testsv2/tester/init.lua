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

local shell    = require 'shell.telnet'
local os       = require 'os'
local sched    = require 'sched'
local print    = print

-- Create a shell for debug (on port 3000)
local s = {}
s.activate = true
s.port = 3000
s.editmode = "edit" -- can be "line" if the trivial line by line mode is wanted
s.historysize = 30  -- only valid for edit mode,








sched.run()