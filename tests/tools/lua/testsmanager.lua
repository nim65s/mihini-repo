#!/usr/bin/lua
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

local os = require 'os'
local system = require 'agent.system'
local io = require 'io'
local lom = require 'lxp.lom'
local tableutils = require 'utils.table'
local pathutils = require 'utils.path'

local targets = nil
local testssuites = nil

function loadconfigfile(configfile)
  -- check input data
  if type(configfile) ~= "string" then
    return nil, "need a valid config file path as argument"
  end

  -- open the specified file
  local fd, err = io.open(configfile)
  if not fd then return nil, err end

  local configstring = fd:read("*a")
  if not configstring then return nil, "Cannot read file content" end
  fd:close()

  return lom.parse(configstring)
end

-- returns the subtable associated to the key value
local function getSubTable(table, key)
  for val,o in tableutils.recursivepairs(table) do
    if o == key then
      local root, tail = pathutils.split(val, -1)
      return pathutils.get(table, root)
    end
  end
end

local function recursiveIterate(t)
    checks('table', '?string')
    local function it(t, prefix, cp)
        cp[t] = true
        local pp = prefix == "" and prefix or "."
        for k, v in pairs(t) do
            k = type(k) == 'number' and '['..tostring(k)..']' or pp..tostring(k)
            if type(v) == 'table' then
                if not cp[v] then it(v, prefix..k, cp) end
            else
                coroutine.yield(prefix..k, v)
            end
        end
        cp[t] = nil
    end

    local prefix = ""
    return coroutine.wrap(function() it(t, pathutils.clean(prefix), {}) end)
end


local function buildTarget(options)
local res, path = system.execute("pwd")
--print(res:read())
--  system.pexec("./buildSpecificAgent.sh "..options.attr.destination.." ../.. "..options.attr.options )
end


local function parseTargets(targetlist)
  local targets={}
  local cpt = 0
  for path, o in recursiveIterate(targetlist) do
     if o == "TARGET" then
       local root, path = pathutils.split(path, -1)
       local target = pathutils.get(targetlist, root)
       targets[#targets+1] = target
     end
  end
  return targets
end


-- Function: maketargets
-- Description:
--   This function take into parameter a config file that specify the list of targets to generate
--   This file shall specify the used name, the destination
function maketargets(configfile, destination)
  local res, err = loadconfigfile(configfile)

  if res then
    local targets = getSubTable(res, "TARGETS")

    if targets and type(targets) == "table" then
      local list = parseTargets(targets)
      for it=1,#list do
         buildTarget(list[it])
      end
    else
      print"Error while loading TARGETS subtree: Not found"
    end
  else
    print("Error: " .. err)
  end

end
-- p(loadconfigfile("./config_all.xml")[2])

maketargets("./config_all.xml")