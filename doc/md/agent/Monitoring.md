Monitoring
==========

#### Monitoring variables

Each monitoring script has its own execution environment. It means that
writing a lua variable will not be visible from another monitoring
script.

In addition to the individual environment the Monitoring engine adds
several tables where to read and write other variables.

- **system**: this table holds all system variables. Usually those
  variables are used in read only.
- **user**: this table holds all the user defined variables.
- **global**: this is a non-monitored table. It can be use to store
  static data.
- **persist**: this is a non-monitored and persisted table. It can
  be used to store data that will survive reboots.

#### Monitoring variables access

Let's say that in the following examples we want to get the Cellular
RSSI value.

##### in a script:

In a script all variables can be accessed in a *natural* Lua way.

~~~~{.lua}
local rssi = system.cellular.rssi
~~~~

##### using Data Reading:

M3DA ReadNode command can be used to read any varaible.

~~~~ {.lua}
Command name: ReadNode
Command path: @sys
Command arg#1: monitoring.system.cellular.rssi
~~~~

##### in Agent context:

In a global Lua environement (in Agent code or in the Lua shell
attached to the Agent).

~~~~{.lua}
local rssi = Monitoring.vars.system.cellular.rssi
~~~~

#### System variables

The following system variables are available, depending on what the
different hardware may provide.

##### Cellular

------------------------------------------------------------------------------------------------------------------------------------------------------
Variable name                Variable Type        Variable description                    Available on
-------------                -------------        --------------------                    ------------------------------------------------------------
cellurar.rssi                integer              Cellular RSSI level                     On any device that support the standard AT+CSQ AT command

cellular.ber                 integer              Cellular BER level                      On any device that support the standard AT+CSQ AT command

cellular.imei                string               Cellular IMEI                           On any device that support the standard AT+CGSN AT command

cellular.imsi                string               SIM IMSI number                         On any device that support the standard AT+CIMI AT command
------------------------------------------------------------------------------------------------------------------------------------------------------

##### Power

------------------------------------------------------------------------------------------------------------------------------------------------------
Variable name                Variable Type        Variable description                    Available on
-------------                -------------        ------------------------------          ------------------------------------------------------------
batterylevel                 integer              Level of charge of the device
                                                  battery

externalpower                boolean              true if the device is powered 
                                                  by an external source
------------------------------------------------------------------------------------------------------------------------------------------------------

##### Memory / CPU

--------------------------------------------------------------------------------------------------------------------------------------------------------------
Variable name                Variable Type        Variable description                            Available on
-------------                -------------        --------------------------------------          ------------------------------------------------------------
luaramusage                  integer              Quantity of memory used by the                  All (included in standard lua)
                                                  Lua VM (the one running the agent) \
                                                  The value is the one returned by 
                                                  collectgarbage("count") preceded by
                                                  a collectgarbage("collect") in order 
                                                  to provided consistent numbers. 
                                                  The direct consequence is that reading 
                                                  this variable has a non null CPU cost.
                                                  Use sparingly.

totalramavailable            integer              Total quantity of RAM available on the          Linux
                                                  system

totalramused                 integer              Total quantity of RAM used on the system        Linux

cpuload                      integer              Average CPU load                                Linux

totalflashavailable          integer              Total quantity of flash available on the 
                                                  system

totalflashused               integer              Total quantity of flash used on the 
                                                  system
---------------------------------------------------------------------------------------------------------------------------------------------------------------

##### NetworkManager


--------------------------------------------------------------------------------------------------------------------------------------------------------------
Variable name                    Variable Type        Variable description                            Available on
-------------                    -------------        ----------------------------------------        --------------------------------------------------------
netman.BEARERNAME.connected      boolean              connection state of the bearer

netman.BEARERNAME.ipaddr         string               ip address of the bearer

netman.BEARERNAME.hwaddr         string               MAC address of the bearer                       Ethernet bearer

netman.BEARERNAME.netmask        string               netmask address of the bearer

netman.BEARERNAME.gw             string               gateway address of the bearer

netman.BEARERNAME.nameserver1    string               dns address #1 (there can be several 
                                                      dns address, usually 2)

netman.BEARERNAME.mountdate      number               timestamp of the last successful mount

netman.BEARERNAME.mountretries   number               number of retries used for the last 
                                                      successful mount

netman.BEARERNAME.RX             number               number of bytes received by this bearer         **Linux only**

netman.BEARERNAME.TX             number               number of bytes transmitted by this             **Linux only** 
                                                      bearer

netman.defaultbearer             string               Default (=selected) bearer: bearer used 
                                                      as default route, variable value is the 
                                                      BEARERNAME
--------------------------------------------------------------------------------------------------------------------------------------------------------------

#### Monitoring Script Engine API

~~~~{.lua}
install(name, script, autoenable)
~~~~

Install a new monitoring script.\
**name** is the name identifying the monitoring script\
**script** is the script content as a Lua string\
**autoenable** when set to true (i.e. non false value), the script is
installed and will be automatically enabled on next Agent boot.\
when set to "now", the script is started right now, but not installed
nor enabled (test purpose),\
when set to false value, the script is installed but not enable for
the next Agent boot,\
when set to nil (or absent), the enable flag will stay unchanged
(meaning equal to the flag of a script that was installed with the
same name)

~~~~{.lua}
uninstall(name)
~~~~

Uninstall an installed monitoring script.\
**name** is the name identifying the monitoring script to uninstall

~~~~{.lua}
uninstallall()
~~~~

Uninstall **all** installed monitoring scripts.

~~~~{.lua}
enable(name)
~~~~

Enable an installed monitoring script: the script will be started on
next Agent boot.\
**name** is the name identifying the monitoring script to enable

~~~~{.lua}
disable(name)
~~~~

Disable an installed monitoring script: the script will not be started
on next Agent boot.\
**name** is the name identifying the monitoring script to disable\
Note: The script remains installed

~~~~{.lua}
registerextvar(var, pushenable, getvar, varlist)
~~~~

This function allows to add additional variables in the monitored
tables\
**pushenable** and **getvar** are functions.\
**pushenable** will be called by the monitoring engine in order to
enable asynchronous mode\
**getvar** will be called if asynchronous push mode is not enabled
and the variable is read.\
**varlist** argument must be provided only when registering group of
variables. **varlist** must be either a table (array) that list the
names of the variables, or a function that returns that table.\
When successful, this function returns the table that holds the
monitored variable or group of variables\
notes:\
if **pushenable** is a string or a number, then **getvar** is ignored
and the value of **pushenable** is set as a static value into the
monitoring variable table\
**pushenable** and **getvar** can be equal to nil, restricting the
usage of that variable, according to what is nil\
**var** can actually a path designating a group of variables, in that
case it must have a trailing '.'. ex 'system.cellular.'\
the actual tables will be automatically created by this function\
**pushenable** and **getvar**, when defined as functions will be
called with two parameters: the path, and the variable name.
**pushenable** may be called with a nil variable name, meaning the
pushenable is on the whole group (=path) of variable.


