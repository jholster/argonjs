AbstractModel = require '../model'
MongoStorage = require './mongo'
Observable = require '../observable'

class ServerModel extends AbstractModel
  @storage = new MongoStorage 'carbon'

  Observable.extend ServerModel

  ServerModel._waiting = 0
  @wait = -> ServerModel._waiting++
  @ready = -> ServerModel.emit 'ready' if --ServerModel._waiting == 0

  @find = (query, options, cb) ->
    console.log @__super__.constructor.name
    console.log @name
    cb = options if not cb
    @wait()
    @storage.find @name, query, options, (err, records) =>
      if records
        records = records.map (json) => new @ json
        records = records.filter (r) -> r.readable()
      cb err, records
      @ready()

  @save = (record, cb) ->
    @wait()
    record = new @ record unless record instanceof @
    if record.writable()
      data = {}
      data[field] = record[field] for field of @_fields
      @storage.save @name, data, (err, result) =>
        cb err, result and (new @ result) or null
        @ready()
    else
      cb 'permission error', null
      @ready()

  @remove = (id, cb) ->
    @find id: id, limit: 1, (err, records) =>
      return cb err if err
      if records and (record = records[0]) and record.writable()
        @storage.remove @name, id: record.id, =>
          cb arguments...
          @ready()
      else
        cb null, 0
        @ready()

exports = module.exports = ServerModel
