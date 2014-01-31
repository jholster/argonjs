class Storage
  find: (model, query, cb)          -> throw "not implemented"
  get: (model, query_or_id, cb)     -> throw "not implemented"
  save: (model, json)               -> throw "not implemented"
  remove: (model, query_or_id, cb)  -> throw "not implemented"

class Storage.Mongo extends Storage
  constructor: (conn_str) ->
    @mongojs = require 'mongojs' # TODO
    @db = @mongojs conn_str

  demongofy: (doc) ->
    doc.id = doc._id.toString()
    delete doc._id
    doc

  mongofy: (json) ->
    if json.id
      json._id = @mongojs.ObjectId json.id
      delete json.id
    json

  find: (model, query, options, cb) ->
    if arguments.length == 3
      cb = options
    else if arguments.length == 2
      cb = query
    @db.collection(model).find (@mongofy query), (err, result) =>
      cb err, result.map @demongofy

  remove: (model, query, cb) ->
    @db.collection(model).remove (@mongofy query), (err, num) =>
      cb err, num

  save: (model, json, cb) ->
    @db.collection(model).save (@mongofy json), safe: true, (err, doc) =>
      cb err, (doc and @demongofy doc or null)

module.exports = Storage
