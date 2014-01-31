class Observable
  @extend = (target) ->
    target[prop] = @::[prop] for prop of @::

  on: (event, cb, once) ->
    ((@observers ?= {})[event] ?= []).push cb
    cb.once = true if once

  once: (event, cb) ->
    @on event, cb, true

  emit: (event, args...) ->
    console.log (@name or @constructor.name), 'emits', event
    @observers ?= {}
    @observers[event] ?= []
    @observers[event] = @observers[event].filter (cb) ->
      cb args...
      not cb.once # filter out onces

  # property: (attr) ->
  #   @properties ?= {}
  #   Object.defineProperty @, attr,
  #     get: ->
  #       @properties[attr]
  #     set: (value) ->
  #       oldie = @properties[attr]
  #       @properties[attr] = value
  #       @emit "change", attr, value, oldie
  #       @emit "change #{attr}", value, oldie

exports = module.exports = Observable
