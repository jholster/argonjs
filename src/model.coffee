Argon = require './argon'
Observable = require './observable'

class AbstractModel
  Observable.extend @

  @field = (name, opts={}) ->
    (@_fields ?= id: {})[name] = opts

  @get: (query, cb) ->
    query = id: query if typeof query != 'object'
    @find query, limit: 1, (err, result) =>
      cb err, result and result[0] or null

  constructor: (json) ->
    if json
      if json.id
        @constructor._identities ?= {}
        if existing = @constructor._identities[json.id]
          existing[k] = v for k, v of json
          return existing
        else
          @constructor._identities[json.id] = @
      @[k] = v for k, v of json

  save: (cb) ->
    @constructor.save @, cb

  remove: (cb) ->
    @constructor.remove id: @id, cb

  readable: -> true
  writable: -> true

  toJSON: ->
    record = {}
    record[name] = @[name] for name of @constructor._fields
    record

exports = module.exports = AbstractModel
