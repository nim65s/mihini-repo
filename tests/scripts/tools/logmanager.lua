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

local log   = require 'log'

-- local logchecker = {}
--
-- -- set the filter the to specified value
-- function logchecker:setFilter(filter)
--   self.filter = filter
-- end
--
-- -- check if the entered value is
-- function logchecker:isMatchingFilter(text)
--   return string.gmatch (text, self.filter)
-- end
--
-- -- check if the log appears in the log table within "delay" time
-- function logchecker:checklog(filter, delay)
--   self:setFilter(filter)
--   self:registerLogger()
--   self.found = false
--   sched.wait(delay)
--   return self.found
-- end
--
-- -- Register the current logger
-- function logchecker:registerLogger()
--   -- the loggers are called with following params (module, severity, logvalue)
--   log.storelogger = function(module, severity, logvalue) if (self:isMatchingFilter(logvalue)) then self.found = true end; end
-- end
--
--
-- -- create a logmanager
-- function new()
--   return {filter = nil, found = false}
-- end
local isverified = false
local filter = ""

function checkfilter()
  return isverified
end

function checklog(module, severity, logvalue)
  if (string.gmatch (logvalue, filter)) then
    isverified = true
  end

end

function setLogFilter(filter)
  isverified = false
  log.storelogger = checklog
end