# Argon, common functionality for browsers and Node.js

Argon = {}

Argon.Observable  = require './observable'
Argon.Renderer    = require './renderer'
Argon.Route       = require './route'
Argon.View        = require './view'
Argon.Socket      = require './client/socket'
Argon.ClientModel = require './client/model'
Argon.Model       = Argon.ClientModel

exports = module.exports = Argon
window?.Argon = exports