Embedded Micro Protocol (EMP)
========================================

#### 1. Presentation

On the embedded target, several processes (tasks/threads/modules/etc,
depending on the target) are running and providing simple services.

The Agent and the different clients (assets) need to exchange data.
This micro protocol specifies the way of exchanging those data.

The communication is done using a standard IPC, i.e. a socket on
localhost. However the protocol does not require that socket must be
used, any transport layer that provide the same level of features can be
used.\
 On a linux target, the Agent proxy opens a socket on localhost,
default port is 9999. The client can connect to it when it needs to send
data or be able to receive data from a remote server.

#### 2. Frame format

All Commands expect a Response. The Response has the same command id and
the same request id, but the bit0 of the status byte is set to 1.

Commands and Responses can be interleaved, and a maximum of **256** Commands
(same or different ones) can be running at the same time.

A frame (Command or Response) is a set of bytes, composed of a header
followed by a payload.

\
 Header is composed of 8 bytes:
 
------------------------------------------------------------------------------------
Frame section                    Size and description
-------------                    ---------------------------------------------------
command id                       2 bytes: Command id (See #List of commands)

type                             1 byte:\
                                  - bit0: 0-command, 1-response\
                                  - bit1-7: reserved (set to 0)

requestid                        1 byte: unsigned integer to code command 
                                 request id

payloadsize                      4 bytes: BigEndian coded unsigned integer.\ 
                                 Size of the payload in bytes
------------------------------------------------------------------------------------

Command payload is encoded in JSON:

------------------------------------------------------------------------------------
Frame section                    Size and description
-------------                    ---------------------------------------------------
payload                          payload of '`payloadsize`' bytes of JSON
------------------------------------------------------------------------------------


Response Payload is composed of bytes which may be interpreted
according to the 'command' field from the header, however it contains at
least 2 bytes that are interpreted as the status of the response:

------------------------------------------------------------------------------------
Frame section                    Size and description
-------------                    ---------------------------------------------------
status                           2 bytes: if status == 0 the command went OK, \ 
                                          if status != 0 an error  occurred. \
                                 The status value is to be interpreted as a \ 
                                 swi_status_t type.

payload                          payload '`payloadsize-2`' bytes of JSON
------------------------------------------------------------------------------------


#### 3.  List of commands and their respective payloads.


Vocabulary:

* App: stands for Application
* Agt: stands for (Mihini) Agent

--------------------------------------------------------------------------------------------------------------------------------------------------------------
ID            Command ID                   Request Direction        Description
--            ----------                   -----------------        ------------------------------------------------------------------------------------------
1             SendData                     Agt<-\>App                Data coming from server:\
                                                                     \
                                                                    **Command payload**: The payload just contains all the data \
                                                                    \
                                                                    **Response payload**: \
                                                                     - _status_: 2 bytes acknowledging the command.
                                           
2             Register                     App-\>Agt                 Register client asset/service to the Agent \
                                                                     \
                                                                     **Command payload**: \
                                                                     - the path for which this client want to receive
                                                                       messages (a JSON string). \
                                                                     \
                                                                     **Response payload**: \
                                                                      - _status_: 2 bytes acknowledging the command. \
                                                                     \
                                                                     **Remarks**:\
                                                                     - It is possible to register several assets for the same IPC\
                                                                        connection by sending several Register commands from that IPC.\
                                                                     - When the IPC is closed, the asset is unregistered automatically.\
                                                                     - If several assets were registered, closing IPC will unregister all\
                                                                       the assets linked to that IPC.
                                           
3             Unregister                   App-\>Agt                  Unregisters a path previously registered with "Register"
                                           
4             ConnectToServer              App-\>Agt                  Forces the agent to connect to the server \
                                                                      The connection is made synchronously if no latency is specified (i.e.
                                                                     the connection is finished when response is sent), otherwise when \
                                                                      a latency is specified the connection is likely to happen after the
                                                                     response is sent. \
                                                                      \
                                                                      **Command payload**: \ 
                                                                      - optional positive integer: the latency in seconds 
                                                                     before executing the connect to server action. If no latency specified,
                                                                     the connexion is made synchronously.\
                                                                     \
                                                                      **Response payload**: \
                                                                      - _status_: 2 bytes acknowledging the command.
                                                                     The response has a status == 0 when no latency was specified and the
                                                                     connection to the server was successful. \
                                                                      If _latency_ was specified, then status==0 means that the connection
                                                                     request was successfully scheduled
                                           
7              RegisterSMSListener         App-\>Agt                  Register a client as a SMS listener to the Agent. \
                                                                      \
                                                                      **Command payload**: a _list_ of two objects: \
                                                                      - _String_: Phone number pattern to listen to. \
                                                                      - _String_: Message content pattern to listen to. \
                                                                      \
                                                                      **Response payload**: \
                                                                      - _status_: 2 bytes acknowledging the command. \
                                                                      if the status is OK (=0) \
                                                                      - _id_: an unsigned integer, giving the registration id, identifying the
                                                                     sms listening registration for the combination: (sms module
                                                                     instance/phone pattern/message pattern). This is the id to be used to
                                                                     call UnregisterSMSListener command. \
                                                                      \
                                                                      **Note**: Patterns syntax should conformed to [Lua
                                                                     patterns](http://www.lua.org/manual/5.1/manual.html#5.4.1)

51             UnregisterSMSListener       App-\>Agt                  Unregister a client as a SMS listener to the Agent. \
                                                                      \
                                                                      **Command payload**: \
                                                                      - _id_: an unsigned integer, the registration id to unregister, as returned
                                                                     by RegisterSMSListener command \
                                                                      \
                                                                      **Response payload**: \
                                                                      - _status_: 2 bytes acknowledging the command.

8              NewSMS                      Agt-\>App                  Notify an application that a SMS is received \
                                                                     \
                                                                      **Command payload:** a _list_ of 3 objects: \
                                                                       - _String_: Phone number of the sender (for incoming messages) / recipient
                                                                     (for outgoing messages) \
                                                                       - _String_: payload of the message \
                                                                       - _Integer_: the registration id (i.e. the id for the couple message
                                                                     pattern and sender pattern) that matched the incoming sms \
                                                                     \
                                                                      **Response:** 2 bytes acknowledgement.

52             SendSMS                     App-\>Agt                  Used by the application to send a SMS \
                                                                     \
                                                                      **Command payload**: a _list_ of 3 objects: \
                                                                       - _String_: Phone number of the recipient of the outgoing message \
                                                                       - _String_: payload of the message \
                                                                       - _String_: format of the SMS, supported values are "8bits", "7bits", "ucs2" \
                                                                      \
                                                                      **Response payload**: \
                                                                       - _status_: 2 bytes acknowledging the command

9              GetVariable                 App-\>Agt                  Retrieve a variable from the Core Agent. \
                                                                      \
                                                                      **Command payload**: a _list_ of 2 objects: \
                                                                       - _String_: name of the variable to get (usually a string that is a path !)
                                                                     \
                                                                       - _Integer_: maximum depth of the variable retrieval. This is useful when
                                                                     doing a get on a sub tree. This should be a number. \
                                                                     \
                                                                      **Response payload**: \
                                                                      - _status_: 2 bytes acknowledging the command. \
                                                                      if the status is OK (=0) \
                                                                      2 objects, can be null. The first object is the value of the variable,
                                                                     or null if the variable is a table. The second object is a list of all
                                                                     sub tree names

10             SetVariable                 App-\>Agt                  Set a variable on the Core Agent. \
                                                                      \
                                                                      **Command payload**: a _list_ of 2 objects: \
                                                                       - 1 _String_ representing the variable to set (usually a string that is a
                                                                     path !) \
                                                                       - 1 _object_ representing the value of the variable (it can be a hashtable)\
                                                                     \
                                                                      **Response payload**: \
                                                                       - _status_: 2 bytes acknowledging the command.

11             RegisterVariable            App-\>Agt                  Register one variable or path to get notification when it changes. \
                                                                      \
                                                                      **Command payload**: a _list_ of 2 objects: \
                                                                       - _reg vars_: list of strings representing the variables to register to,
                                                                       each string is a path to register to \
                                                                       - _passive vars_: list of strings, each string identifying the path of a
                                                                     passive variable \
                                                                      \
                                                                      **Response payload**: \
                                                                      - _status_: 2 bytes acknowledging the command. \
                                                                      - _registration id_: string identifying this registration for variable
                                                                     change, this id is to be given to DeRegisterVariable command.

12             NotifyVariable              Agt-\>App                  Notify that a variable changed. \
                                                                      \
                                                                      **Command payload**: a _list_ of 2 objects: \
                                                                      - 1 _string_ representing the registration id that provoked this
                                                                     notification \
                                                                      - 1 _map_ representing the variables data sent in the change notification,
                                                                     map keys are variables full path, map values are variable values, the
                                                                     map contains both registered variables that have changed and passive
                                                                     variables set in register request \
                                                                      \
                                                                      **Response payload**: \
                                                                       - status: 2 bytes acknowledging the command.

13             DeRegisterVariable          App-\>Agt                  Cancel previous registration for watching variable changes. \
                                                                      \
                                                                      **Command payload**: \
                                                                       - _String_ representing the registration id (sent in RegisterVariable
                                                                     command Response payload) \
                                                                      \
                                                                      **Response payload**: \
                                                                       - _status_: 2 bytes acknowledging the command.

20             SoftwareUpdate              Agt-\>App                  Notify the Application that an update must be downloaded and installed
                                                                     from the url given into payload. \
                                                                      \
                                                                      **Command payload**: \
                                                                       - _componentname_: string that contains the application / bundle to update
                                                                     (the path **does contain** the assetid of the asset responsible for that
                                                                     update) \
                                                                       - _version_: string, empty string (but not null!) to specify
                                                                     de-installation request, non empty string for regular update/install of
                                                                     software component. \
                                                                       - _URL_: string; Can be empty when version is empty too, otherwise URL will
                                                                     be a non empty string defining the url (can be local) from which the
                                                                     application has to be updated and an optional username and userpassword
                                                                     ex *url:username@password* (username and/or password can be empty). \
                                                                       - _params_: a _map_ whose content depends on the Application and the content
                                                                     of the Update package received by the Agent. Those params provide a
                                                                     way to give application specific update params. \
                                                                      \
                                                                      **Response payload**: \
                                                                       - _status_: 2 bytes acknowledging the command \
                                                                      \
                                                                      **Note**: There can be only one SoftwareUpdate request at a time.

21             SoftwareUpdateResult        App-\>Agt                  Return the result of the previous SoftwareUpdate request. \
                                                                      \
                                                                      **Command payload**: a _list_ of 2 objects: \
                                                                       - _componentname_: a string holding the name of the component \
                                                                      update status code: integer (see [Software Update
                                                                     Module](Software_Update_Module.html) error code documentation) \
                                                                      \
                                                                      **Response payload**: \
                                                                       - _status_: 2 bytes acknowledging the command \
                                                                      \
                                                                      **Note**: There can be only one SoftwareUpdate request at a time.

22             SoftwareUpdateStatus        Agt-\>App                  Notify the application that the update's status has changed \
                                                                      \
                                                                      **Command payload**: a _list_ of 2 objects: \
                                                                       - _status_: an integer representing the current update status. \
                                                                       - _details_: a string containing additional informations for this status.

23             SoftwareUpdateRequest       App-\>Agt                  Request agent to change the current update status \
                                                                      \
                                                                      **Command payload**: \
                                                                       - _status_: an integer representing the new required update status.

24             RegisterUpdateListener      App-\>Agt                  Register a callback to be called when the update status has changed.
                                                                      \
                                                                      This registration is not specific to the asset, the registration is
                                                                      available for the whole application

25             UnregisterUpdateListener    App-\>Agt                  Unregister the callback previously registered by the application

30             PData                       App-\>Agt                  Push some unstructured data to the data manager \
                                                                      \
                                                                      **Command payload:** \
                                                                      an hashmap with fields:
                                                                      - asset: name of the asset \
                                                                      - queue: triggering policy (nil refers to the default policy) \
                                                                      - path: common path prefix for sent data \
                                                                      - data: possibly nested table of path suffix / data pairs \
                                                                          \
                                                                      **Response:** 2 bytes acknowledgement.

32             PFlush                      App-\>Agt                  Force the immediate flush of a given trigger policy. \
                                                                     \
                                                                      **Command payload:** an hashmap with a field "policy" containing the
                                                                     name of the policy to flush. If no name is given, the "default" policy
                                                                     is flushed. \
                                                                     \
                                                                      **Response:** 2 bytes acknowledgement.

33             PAcknowledge                App-\>Agt                  Push an acknowledge to data manager, given trigger policy. \
                                                                      \
                                                                      **Command payload:** \
                                                                      an hashmap with a fields:
                                                                      - _ticket_: the ticket identifying the message to acknowledge,\
                                                                      - _status_: status code (integer) for the acknowledge (0=OK, other value
                                                                        means error)\
                                                                      - _message_: error message to send along with status code in the
                                                                        acknowledge\
                                                                      - _policy_: triggering policy (nil refers to the default policy)\
                                                                      - _persisted_: whether the acknowledge has to be stored in ram or flash.\
                                                                          \
                                                                      **Response:** 2 bytes acknowledgement.

40             TableNew                    App-\>Agt                  Create a new structured table \
                                                                      \
                                                                      **Command payload:** \
                                                                      an hashmap with fields:
                                                                      - _asset_: name of the asset\
                                                                      - _storage_: "ram" or "flash"\
                                                                      - _policy_: triggering policy (nil refers to the default policy)\
                                                                      - _path_: common path prefix for table data\
                                                                      - _columns_: columns configuration, as used by stagedb's constructor. \
                                                                      \
                                                                      **Response:** 2 bytes acknowledgement, plus a table identifier to
                                                                         be used in further operations on this table

41             TableRow                    App-\>Agt                  Push a row of data in an existing data table \
                                                                      \
                                                                      **Command payload:** \
                                                                      an hashmap with fields:
                                                                       - _table_: table identifier
                                                                       - _row_: map of data to push, which format is { columnname1 = value,
                                                                        columnname2 = value, ... }\
                                                                          \
                                                                      **Response**: 2 bytes acknowledgement.

43             TableSetMaxRows             App-\>Agt                  Set a maximum number of rows in the table. The table will auto-flush
                                                                     itself when it reaches that number \
                                                                      \
                                                                      **Command payload:** \
                                                                      an hashmap with fields:
                                                                       - _table_: table identifier
                                                                       - _maxrows_: max \# of row in the table \
                                                                     \
                                                                      **Response:** 2 bytes acknowledgement.

44             TableReset                  App-\>Agt                  Remove all content from a table \
                                                                      \
                                                                      **Command payload:** \
                                                                      an hashmap with fields:
                                                                       - _table_: table identifier \
                                                                      \
                                                                     **Response:** 2 bytes acknowledgement.

45             ConsoNew                    App-\>Agt                  Setup a new consolidation table \
                                                                     \
                                                                     **Command payload:** \
                                                                     an hashmap with fields:
                                                                     - src: source table identifier
                                                                     - path: common path prefix for table data
                                                                     - columns: columns configuration, as used by stagedb's constructor
                                                                     - storage: "ram" or "flash"
                                                                     - send\_queue: send triggering policy for destination table (nil
                                                                       refers to the default policy)
                                                                     - conso\_queue: consolidation policy for source table (nil refers to
                                                                       the default policy) \
                                                                     \
                                                                     **Response:** 2 bytes acknowledgement, plus destination table
                                                                       identifier to be used in further operations on this table

46             ConsoTrigger                App-\>Agt                  nsolidate content of table immediately \
                                                                     \
                                                                     **Command payload:** \
                                                                     an hashmap with fields:\
                                                                     - table: table identifier\
                                                                     - dont\_reset: (Boolean) if true, the table's content isn't erased\
                                                                       after it's been consolidated. \
                                                                     \
                                                                     **Response:** 2 bytes acknowledgement.

47             SendTrigger                 App-\>Agt                  Send content of table to server immediately \
                                                                     \
                                                                     **Command payload:** \
                                                                     an hashmap with fields:
                                                                     - table: table identifier
                                                                     - dont\_reset: (Boolean) if true, the table's content isn't erased
                                                                       after it's been sent. \
                                                                       \
                                                                     **Response:** 2 bytes acknowledgement.

50             Reboot                      App-\>Agt                  Requests reboot of the system running the Agent. The reboot will
                                                                     occur after a small delay. \
                                                                     **Command payload:**\
                                                                      - reason: string describing the reason to request the reboot, the\
                                                                        reason will be displayed in the Agent logs.\
                                                                     \
                                                                     **Response:** 2 bytes acknowledgement.

--------------------------------------------------------------------------------------------------------------------------------------------------------------


