fs = require 'fs'
os = require 'os'
http = require 'http'
path = require 'path'
send = require 'send'
https = require 'https'
cluster = require 'cluster'

watch = require('chokidar').watch # replacement for buggy fs.watch
jsdom = require 'jsdom'
connect = require 'connect'

SocketServer = require './socket'
Model = require './model'

# http://dshaw.github.io/2012-05-jsday/#/14
# http://stackoverflow.com/questions/8312171/can-i-run-node-js-with-low-privileges

class Server

  constructor: (@app, @options = {}) ->

    # Read options from command line
    for arg in process.argv.slice 1 when '=' in arg
      [name, value] = arg.split '='
      @options[name] = value

    # Default options
    @options.debug        ?= process.platform in ['darwin', 'win32']
    @options.project_path ?= process.cwd()
    @options.static_dir   ?= @options.project_path + (@options.debug and '/build' or '/dist')
    @options.static_url   ?= '/_static/'
    @options.ssl          ?= @ssl_autoconfig()
    @options.port         ?= @options.debug and 3000 or (@options.ssl and 443 or 80)
    @options.cluster      ?= not @options.debug and os.cpus().length or false
    @options.redirect     ?= true # redirect http -> https if ssl enabled
    @options.indexing     ?= true # server-side rendering for search bots

    # Set up the server(s)
    if @options.cluster and cluster.isMaster
      cluster.fork() for i in [1..@options.cluster]
    else
      # Expose the listener to be extended with Connect.js middleware etc
      @listener = connect()

      # Remove trailing slash (a historic artifact carrying no meaningful information)
      @listener.use (require 'connect-slashes') false

      # Serve static files
      @static @options.static_url, @options.static_dir

      # Serve source map files in debug mode (TODO: /src -> /_static/src)
      @static '/src', '/src', false if @options.debug

      # Listen for incoming HTTP(S) connections
      if @options.ssl
        @server = https.createServer(@options.ssl, @listener).listen @options.port
        @create_redirect_server(80, 443) if @options.redirect and @options.port == 443
      else
        @server = http.createServer(@listener).listen port

      # Handle websocket connections
      #context = (property for property of @app when property instanceof Model)
      context = @app
      authenticate = (info, cb) ->
        #user = @app.authenticate
        #info.req.user = user
        cb true
      @socket = new SocketServer @server, context, authenticate

      # Use proper <meta> tag for favicon instead of braindead Redmond-originating /favicon.ico
      @listener.use '/favicon.ico', (req, res) -> res.writeHead 404; res.end()

      # Handle requests
      if @options.indexing
        # Run the application logic and pre-render the landing page,
        # enabling search bots seeing the content and clients getting
        # real status codes (e.g. 404) at the cost of some CPU cycles.
        # Note: no UI events are handled server-side – the client-side code
        # will run identically regardless of the server-side pre-rendering.
        markup = fs.readFileSync @options.static_dir + '/index.html'
        jsdom.env
          html: markup
          features: FetchExternalResources: false
          done: (errors, window) =>
            global[k] = v for k, v of window when typeof global[k] == 'undefined'
            @listener.use '/', (req, res) =>
              t = new Date
              fn_view = @app::dispatch req.url, true
              @app::current.once 'rendered', ->
                res.write window.document.innerHTML
                res.end()
                console.log '>>> served ', req.url ,' in ', (new Date - t) , ' msecs'
              fn_view()
      else
        # Optimize performance by serving only a static content without running
        # the application logic. Useful for non-public / login-required webapps.
        @listener.use '/', (req, res) =>
          send(req, '/index.html').root(@options.static_dir).pipe(res)

  # Shortcut for serving the content of directory as static files
  static: (url, dir, live = @options.debug) ->
    expires = @options.debug and 0 or (3600 * 24 * 365)
    @listener.use url, connect.static dir, maxAge: expires
    @livereload url, dir if live

  # Notify the client about static file changes
  livereload: (url, dir) ->
    watch(path.normalize(dir)).on 'change', (path) =>
      fs.readFile path, (err, buf) =>
        @socket.broadcast
          namespace: 'livereload'
          path: url + path.slice dir.length + 1 # replace dir by url
          content: buf.toString()

  # Enable SSL if key/certificate files exist in the project directory
  ssl_autoconfig: ->
    try
      ssl =
        key: fs.readFileSync @options.project_path + '/ssl/server.key'
        cert: fs.readFileSync @options.project_path + '/ssl/server.crt'
      ssl
    catch file_not_found
      false

  # Redirect non-secure requests to secure server
  create_redirect_server: (port_from, port_to) ->
    http.createServer((req, res) ->
      secure_host = req.headers.host.replace /:[0-9]+/, ":#{port_to}"
      res.writeHead(301, Location: 'https://' + secure_host + req.url)
      res.end()
    ).listen port_from

exports = module.exports = Server
