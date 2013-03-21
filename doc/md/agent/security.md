# M3DA Server connection and security

## Overview

Data transmission from the agent to the server are handled in M3DA. It goes
through several modules:

* A transport module, which exchanges LTN12 byte streams with the
  server, called `m3da.transport.xxx`. Currently supported transport
  layers are `tcp` and `http`.

* A session module, which converts between M3DA messages on the agent
  side, and byte streams on the transport side. Messages come from the
  agent as LTN12 source factories, i.e. functions returning an LTN12
  source; the use of LTN12 allows to stream large messages without
  holding them entirely in RAM; they're passed as factories, because
  the session might have to emit them more than once, e.g. if an
  authentication failure occurred at the first attempt.

  In the other direction, server messages going to the agent, they're
  received by the session through an LTN12 sink, then pushed, one
  serialized message at a time, to a callback passed at initialization
  time. Those messages are expected to be rather short, hence are
  passed as strings rather than streams.

  The session layer is in charge of putting sent messages into M3DA
  envelopes (and extracting incomping messages from their
  envelopes). Currently supported session layer are
  `m3da.session.default` and `m3da.session.security`, the latter
  supporting mandatory authentication, plus optional encryption and
  password provisioning.

* The provisioning module is triggered by the security session module
  when it lacks its authentication+encryption password. It uses a
  registration password (generally shared by several devices) to
  retrieve an actual password (proper to a single device).

* agent.srvcon handles communications for the agent: it initializes
  transport and session layers, accumulates data streams to send to
  the server, dispatches incoming server messages to the appropriate
  asset connector.

## Detailed API

### Transport modules

Transport modules must have a function `new(url)`, which returns `nil`
+ error message upon failure, or an object with the following properties:

* a `:send(src)` method, sending the content of an LTN12 source to the
  server, returning a non-nil value upon success, `nil`+error message
  upon failure;

* a `sink` field, to be set externally, which contains an LTN12 sink
  where data coming from the server are fed.

The `url` parameter of the `new()` function must be sufficient to
fully configure the transport layer, and the scheme part of the url
(the initial word before `"://"`) must match the last part of the
module name.

### Session modules

Session modules must have a function `new(cfg)`, which returns `nil`
+ error message upon failure, or an object with the following
properties:

* a `:send(src_factory)` method, whose parameter is a function
  returning an LTN12 source. The source must stream a serialized M3DA
  message, and if `src_factory` is called more than once, it must be
  able to serve the source more than once. If `src_factory` is called
  a second time, returning a second source, the first source will not
  be used anymore. `:send()` return non-`nil`, or `nil` + error
  message.

* a `:newsink()` method, which returns an LTN12 sink. This sink will
  receive data from the transport layer; those data represent
  (possibly partial) M3DA envelopes sent by the server to the agent.

The `cfg` parameter for `new()` is a table. It must have the following
fields, plus optionally some others specific to a given session type:

* `transport` is an already initialized transport object. The session
  initializer must set its `sink` field.

* `msghandler` is a function which will be called by the session
  object everytime a message is received from the server. This
  function takes a single parameter, which consists of one or several
  M3DA messages serialized into a string.

* `localid` is the device's identifier.

* `peerid` is the server's identifier.

### agent.srvcon

The server connector has the following public APIs:

* `init()` initializes the module; it retrieves its parameters from
  `agent.config`.

* `pushtoserver(src_factory, callback)` accumulates data to be sent to
  the server. Data is represented as an LTN12 source factory; an
  optional callback function can be provided: it will be executed once
  the data will have been successfully sent to the server.

* `connect(delay)` ensures that all data accumulated with
  `pushtoserver()` and not yet successfully sent, will be sent to the
  server in no more than `delay` seconds.
