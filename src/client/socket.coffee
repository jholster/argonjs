Observable = require '../observable'

class SocketClient extends Observable
  @pool: {}
  id: 1
  queue: []
  sent: {}

  constructor: (url) ->
    url ?= (location.protocol == 'https:' and 'wss://' or 'ws://') + location.host if location?
    return instance if instance = @constructor.pool[url] # re-use existing instance with same url
    @constructor.pool[url] = @
    @url = url
    @connect()

  connect: ->
    if not @connecting and WebSocket?
      console.log "connecting..."
      @connecting = true
      @socket = new WebSocket @url
      @socket.onmessage = @receive.bind @
      @socket.onopen = =>
        console.log 'connected'
        @connecting = false
        clearInterval @interval
        @interval = null
        @flush()
      @socket.onclose = =>
        console.log 'closed'
        @connecting = false
        @interval = setInterval (@connect.bind @), 2000 unless @interval

  call: (method, params=[], cb) ->
    request = method: method, params: params, id: @id++
    call = request: request, cb: cb
    @queue.push call
    @flush()
    @timer = setTimeout @timeout.bind(@, call), 2000
    @update()

  flush: ->
    # TODO: send() internally buffers, ditch our queue?
    while @socket.readyState == WebSocket.OPEN and call = @queue.shift()
      console.log 'remote call', call.request
      @socket.send JSON.stringify call.request
      @sent[call.request.id] = call

  receive: (event) ->
    message = JSON.parse event.data
    if message.id and response = message
      if call = @sent[response.id] # else timed out
        console.log 'response', response
        if response.error # DEBUG
          console.error response.error
        delete @sent[response.id]
        clearTimeout @timer
        call.cb response.error, response.result
        @update()
    else
      @emit 'notify', message # broadcast received

  timeout: (call) ->
    if @sent[call.request.id]
      console.log 'timing out:', call.request.method
      call.cb 'timeout', null
      delete @sent[call.request.id]
      @queue = @queue.filter (item) -> item != call
      @update()

  update: -> # TODO: de-couple
    waiting = @queue.length or (Object.keys @sent).length
    if not @_waiting and waiting
      @_waiting = new Date
      @emit 'waiting'
      @_waiting_timer = setTimeout =>
        document.documentElement.dataset.state = 'waiting' if @_waiting
      , 250
    else if @_waiting and not waiting
      console.log "waited for #{new Date - @_waiting} msecs"
      @_waiting = null
      document.documentElement.dataset.state = 'idle'
      clearTimeout @_waiting_timer
      @emit 'ready'

exports = module.exports = SocketClient
