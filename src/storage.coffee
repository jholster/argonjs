class Storage
  find: (model, query, cb)          -> throw "not implemented"
  get: (model, query_or_id, cb)     -> throw "not implemented"
  save: (model, json)               -> throw "not implemented"
  remove: (model, query_or_id, cb)  -> throw "not implemented"

exports = module.exports = Storage
