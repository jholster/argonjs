// Generated by CoffeeScript 1.6.3
var Observable, SocketClient, exports,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Observable = require('../observable');

SocketClient = (function(_super) {
  __extends(SocketClient, _super);

  SocketClient.pool = {};

  SocketClient.prototype.id = 1;

  SocketClient.prototype.queue = [];

  SocketClient.prototype.sent = {};

  function SocketClient(url) {
    var instance;
    if (typeof location !== "undefined" && location !== null) {
      if (url == null) {
        url = (location.protocol === 'https:' && 'wss://' || 'ws://') + location.host;
      }
    }
    if (instance = this.constructor.pool[url]) {
      return instance;
    }
    this.constructor.pool[url] = this;
    this.url = url;
    this.connect();
  }

  SocketClient.prototype.connect = function() {
    var _this = this;
    if (!this.connecting && (typeof WebSocket !== "undefined" && WebSocket !== null)) {
      console.log("connecting...");
      this.connecting = true;
      this.socket = new WebSocket(this.url);
      this.socket.onmessage = this.receive.bind(this);
      this.socket.onopen = function() {
        console.log('connected');
        _this.connecting = false;
        clearInterval(_this.interval);
        _this.interval = null;
        return _this.flush();
      };
      return this.socket.onclose = function() {
        console.log('closed');
        _this.connecting = false;
        if (!_this.interval) {
          return _this.interval = setInterval(_this.connect.bind(_this), 2000);
        }
      };
    }
  };

  SocketClient.prototype.call = function(method, params, cb) {
    var call, request;
    if (params == null) {
      params = [];
    }
    request = {
      method: method,
      params: params,
      id: this.id++
    };
    call = {
      request: request,
      cb: cb
    };
    this.queue.push(call);
    this.flush();
    this.timer = setTimeout(this.timeout.bind(this, call), 2000);
    return this.update();
  };

  SocketClient.prototype.flush = function() {
    var call, _results;
    _results = [];
    while (this.socket.readyState === WebSocket.OPEN && (call = this.queue.shift())) {
      console.log('remote call', call.request);
      this.socket.send(JSON.stringify(call.request));
      _results.push(this.sent[call.request.id] = call);
    }
    return _results;
  };

  SocketClient.prototype.receive = function(event) {
    var call, message, response;
    message = JSON.parse(event.data);
    if (message.id && (response = message)) {
      if (call = this.sent[response.id]) {
        console.log('response', response);
        if (response.error) {
          console.error(response.error);
        }
        delete this.sent[response.id];
        clearTimeout(this.timer);
        call.cb(response.error, response.result);
        return this.update();
      }
    } else {
      return this.emit('notify', message);
    }
  };

  SocketClient.prototype.timeout = function(call) {
    if (this.sent[call.request.id]) {
      console.log('timing out:', call.request.method);
      call.cb('timeout', null);
      delete this.sent[call.request.id];
      this.queue = this.queue.filter(function(item) {
        return item !== call;
      });
      return this.update();
    }
  };

  SocketClient.prototype.update = function() {
    var waiting,
      _this = this;
    waiting = this.queue.length || (Object.keys(this.sent)).length;
    if (!this._waiting && waiting) {
      this._waiting = new Date;
      this.emit('waiting');
      return this._waiting_timer = setTimeout(function() {
        if (_this._waiting) {
          return document.documentElement.dataset.state = 'waiting';
        }
      }, 250);
    } else if (this._waiting && !waiting) {
      console.log("waited for " + (new Date - this._waiting) + " msecs");
      this._waiting = null;
      document.documentElement.dataset.state = 'idle';
      clearTimeout(this._waiting_timer);
      return this.emit('ready');
    }
  };

  return SocketClient;

})(Observable);

exports = module.exports = SocketClient;

/*
//@ sourceMappingURL=socket.map
*/
