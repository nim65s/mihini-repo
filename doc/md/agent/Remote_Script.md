Remote Script
=============

This Agent feature enables to run **Lua scripts** automatically on
the device.

#### Script Delivery

The script is sent by the server using :

-   New AWT-DA command that provides access to Lua bytecode using url.

So it takes advantage of:

-   Task automation on server
-   Task scheduling on server
-   Task acknowledgment
-   ...

#### Security


The script will be executed with **no restriction**, so the content of
the script is very **delicate**.\
 We need to check integrity and authenticate the sender of the script
(i.e. the server).

The script will have to be signed and the signature will have to be sent
with the script.\
 The choice in the security technique and how the signature will be sent
is highly related to AWT-DA Security enhancement.

#### Script API

The only constraint about a remote script is that it must **throw** an
error to report an failure during the execution.\
 The error will be caught and reported to the server.\
 The error can be thrown:

-   using an API that throw errors like assert()
-   manually call error() function

#### M3DA Command Description

See ExecuteScript command in [Device
Management](Device_Management.html)

#### Some interesting purposes

##### Light Update

In order to provide some update capabilities to the ReadyAgent on Open
AT, the Remote Script can be used to update software parts.\
 It is **not** targeted to update **big part of code**, but fit for
remote command execution, small code update, ...

Note : To update large amount of code, others functionalities exist:

-   on Linux: [Software Update
    Packages](Software_Update_Package.html)

Restrictions of Light Update on Open AT:

-   only **lua code** can be updated
-   only **applicative data**, it's not possible to update firmware
    parts

##### Basic update script

This script installs a small new application in Application Container.

~~~~{.lua}
local appc = require"ApplicationContainer"

local my_app_code = [[
local sched = require "sched"

local function run()
  print("my_app started")
  sched.wait("myapp", "stop")
  print("my_app stop received")
  return "ok"
end

local function stop()
 sched.signal("myapp", "stop")
end

return {run = run, stop = stop}
]]

local res, err = appc.install_lua_app("my_app_id", my_app_code, true)
if not res then error(err) end
~~~~

##### Monitoring Script Update

~~~~{.lua}
local m = require "Monitoring"
local script = "local function action() local data = {var1 = { timestamps = {time()}, data = {system.var1} }}; sendtimestampeddata('system', data); end; connect(onchange('system.var1'),action)"
local res, err = m.install("script1",script)
if not res then error(err) end
~~~~

