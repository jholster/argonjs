Route = require './route'
Renderer = require './renderer'
Observable = require './observable'

class View extends Observable
  root: '/'
  current: null
  routes: {}
  user: null

  @route: (pattern, options) ->
    name = options?.as or @name
    @::routes[name] = new Route @::root + pattern, new @

  start: ->
    window.onpopstate = => @dispatch location.pathname

  navigate: (path) ->
    history.pushState null, '', path unless path == location.pathname
    @dispatch path

  reload: ->
    @dispatch location.pathname

  dispatch: (path, defer) ->
    for name, route of @routes
      if params = route.match path
        @current = route.view
        @emit 'view' # add global hook which checks for view.authenticate flag
        fn = -> route.view.view params...
        return not defer and fn() or fn
    throw 'add .* as last route for 404 (' + path + ')'

  render: (templates) ->
    for into, source of templates
      template = document.querySelector "#template-#{source}"
      into = document.querySelector '#' + (into or 'main')
      into.removeChild node while node = into.lastChild # clean the previous rendering if any
      if template.content instanceof DocumentFragment # clone the template
        into.appendChild template.content.cloneNode(true)
      else
        into.appendChild node.cloneNode(true) for node in template.childNodes
      new Renderer into, @
    @emit 'rendered'

  # Livereload - TODO: decouple
  (new (require './client/socket')).on 'notify', (message) ->
    if message.namespace == 'livereload'
      resource = message
      extension = resource.path.match(/\.[^\.]+$/)?[0]
      if extension == '.css'
        link = document.querySelector "link[rel=stylesheet][href^=\"#{resource.path}\"]"
        link?.href = resource.path + '?' + (new Date).getTime()
      else if extension == '.js'
        document.location.reload false # TODO: bypass the cache?
      else if extension == '.html'
        # Note: only <template> tag reloading supported, not "root" html
        # Idea: can we just replace the whole html/body?
        throwaway = document.createElement 'div'
        throwaway.innerHTML = resource.content
        for template in throwaway.querySelectorAll 'template'
          (document.getElementById template.attributes.id)?.innerHTML = template.innerHTML
        @constructor::current.render()

exports = module.exports = View