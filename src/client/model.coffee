AbstractModel = require '../model'
SocketClient = require './socket'

class ClientModel extends AbstractModel
  @remote = new SocketClient
  @remote.on 'ready', => @emit 'ready'

  @find = (query, options, cb) ->
    cb = options if not cb
    @remote.call "#{@name}.find", [query, options], (err, records) =>
      cb err, records and (records.map (r) => new @ r) or null

  @save = (record, cb) ->
    @remote.call "#{@name}.save", [record], (err, record) =>
      cb err, record and (new @ record) or null

  @remove = (args..., cb) ->
    @remote.call "#{@name}.remove", args, cb

exports = module.exports = ClientModel
