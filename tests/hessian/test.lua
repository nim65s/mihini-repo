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

path='/home/fabien/src/'
dofile (path..'hessian/string.lua')
package.loaded['hessian.string'] = hessian.string
dofile (path..'hessian/source.lua')
package.loaded['hessian.source'] = hessian.source
dofile (path..'hessian/filter.lua')
package.loaded['hessian.filter'] = hessian.filter
dofile (path..'awtda/source.lua')
package.loaded['awtda.source'] = awtda.source

dofile  '/home/fabien/win/src/platform-embedded-6/luafwk/common/misc/pipe.lua'

hsrc, asrc = hessian.source, awtda.source


function printf(...) return print(string.format(...)) end

log.setlevel('ALL','pipe', 'hsrc')

function d(src)
    if iscallable(src) then
        local sink, t = ltn12.sink.table()
        ltn12.pump.all(src, sink)
        src = table.concat(t)
    end
    local t = type(src)
    if t ~= 'string' then print ('<'..t..'>'); return src end
    local function esc10(k) return '\\'..string.byte(k) end
    local function esc16(k) return string.format('\\0x%02x', string.byte(k)) end
    local r10 = src :gsub('\\', '\\\\') :gsub('[%z\1-\31\127-\255]', esc10)
    local r16 = src :gsub('\\', '\\\\') :gsub('[%z\1-\31\127-\255]', esc16)
    print('['..r10..']\n['..r16..']')
   return src
end

hstr, hsrc = hessian.string, hessian.source


function l()
    dofile (path..'hessian/test.lua')
end

COLMAX = 32

-- convert a simpledb into an hessian-serialized map source
function sdb2src(sdb)
    print "flushing database"

    local map = hsrc :map()
    sched.run(function()
        for _, colname in ipairs (sdb.colnames) do
            print ("flushing database column "..colname)
            local lst = hsrc :list() :setmaxlength (COLMAX)
            map :add (hsrc (colname))
            map :add (lst)
            for x in sdb :gcolumn (colname) do lst :add (hstr(x)) end
            lst :close()
        end
        map :close()
    end)
    print "ltn12.source ready"
    return map
end

function pstep(src, snk)
end

function sdbflush()
    local source   = sdb2src(sdb)
    local sink, t  = ltn12.sink.table()
    local headers  = { dev=Config.agent.deviceId; app='app' }
    local envelope = hessian.filter :recenvelope ('', headers)
    ltn12.pump.all (ltn12.source.chain(source, envelope), sink)
    local result = table.concat(t)
    printf ("Serialized %d bytes", #result)
    sdb :clean()
    return result
end


DBSIZE = 256

require 'simpledb'
sdb = simpledb.newsdb({'latitude', 'longitude', 'timestamp', 'temperature'}, DBSIZE-1, sdbflush)


function fdb(n)
    local lat, long, t = 43.53620, 1.5131, 25
    for i = 1, (n or DBSIZE) do
        sdb :addrecord (lat, long, os.time(), t)
        lat, long, t = lat+math.random()/1000, long+math.random()/1000, t + math.random(10)/10
    end
end

