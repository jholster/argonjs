ws = require 'ws'

class SocketServer extends ws.Server

  constructor: (http_server, @context, authenticate) ->
    super server: http_server, verifyClient: authenticate
    @on 'connection', @listen.bind @

  # constructor: (server, @context) ->
  #   ws = require 'ws'
  #   @socket = new ws.Server server: server
  #   @socket.on 'connection', @listen.bind @
  #   # @socket.on 'headers', ->
  #   #   console.log arguments

  listen: (connection) ->
    console.log 'client connected'
    #user = connection.upgradeReq.user # TODO: pass to callable (how?)
    user = undefined
    connection.on 'message', (message) =>
      console.log 'message received', message
      request = JSON.parse message
      reply = (error, result) ->
        response = result: result, error: error, id: request.id
        connection.send JSON.stringify response
      if (callable = @resolve(request.method)) instanceof Function
        @invoke callable, request.params, (error, result) =>
          if not user and result?.constructor.authenticate instanceof Function
            user = result # FIXME
            console.log 'client authenticated as', user
          console.log 'sending back', error, result
          reply error, result if request.id
      else reply "invalid method: #{request.method}", null

  resolve: (keypath) ->
    keypath = keypath.split '.' if typeof keypath == 'string'
    obj = @context
    try
      for key in keypath
        parent = obj
        obj = obj[key]
      obj.bind parent
    catch type_err
      console.log "failed to resolve #{keypath} from #{@context}"
      null

  invoke: (callable, params, cb) ->
    try
      if callable.length > params.length
        # async (fails if optional params missing)
        callable params..., cb
      else
        #sync
        console.log "WARNING: invoking synchronous callable"
        ret = callable params...
        cb null, [ret]
    catch err
      cb err.message, null

  broadcast: (notify) ->
    for client in @clients
      client.send JSON.stringify notify

exports = module.exports = SocketServer
