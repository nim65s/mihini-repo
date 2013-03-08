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

local print   = print
local table   = table
local require = require
local setmetatable = setmetatable
local p = p
--local rpc     = require 'rpc'

module(...)
targetmanagerapi = {}

-- Function: new
-- Description: create a new instance for the specified target
-- Return: the newly created instance if valid, nil otherwise
function new(specificfile, config, svndir, targetdir)
  if not specificfile then return nil end
  if not config then return nil end

  local instance = setmetatable({ target = require(specificfile), config = config.config, testslist = config.tests, svndir = svndir, targetdir = targetdir }, {__index=targetmanagerapi})
p(instance)
  return instance
end

-- Function: compile
-- Description: compile the ReadyAgent and the tests for the target
-- Return: the status of the compilation process
function targetmanagerapi:compile()
  local tar = self.target
  return tar.compile(self.config, self.svndir, self.targetdir)
end

-- Function: install
-- Description: install the ReadyAgent on the target
-- Return: the status of installation, nil and error if any error occurs
function targetmanagerapi:install()
  local tar = self.target
  return tar.install(self.config, self.svndir, self.targetdir)
end

-- Function: start
-- Description: start the ReadyAgent on the target
-- Return: the status of the run, ie the number of errors that occured during the run
function targetmanagerapi:start()
  self.target.start(self.config, self.svndir, self.targetdir)
end

function targetmanagerapi:stop()
  self.target.stop(self.config, self.svndir, self.targetdir)
end

function targetmanagerapi:restart()
  self.target.restart(self.config, self.svndir, self.targetdir)
end

function targetmanagerapi:rpc()
  if not self.rpc then
    assert(self.config.Host)

    -- create rpc connection with the target
    self.rpc = rpc.connect(self.config.Host, self.config.RPCPort)

    if not self.rpc then error("Can't connect to host: ".. self.config.Host) end
  end

  return self.rpc
end
