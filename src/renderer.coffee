class Renderer
  stack: []

  push: (context) ->
    @stack.unshift context

  pop: -> @stack.shift()

  get: (key) ->
    for context in @stack
      obj = context[key]
      if typeof obj != 'undefined'
        return typeof obj == 'function' and (obj.bind context) or obj
    console.log 'not found from stack', key, @stack

  resolve: (keypath) ->
    if path = keypath.split '.'
      obj = @get path.shift()
      for key in path when obj?
        parent = obj
        obj = obj[key]
      console.log "cannot resolve keypath #{keypath}" unless obj?
      typeof(obj) == 'function' and (parent and obj.bind parent) or obj

  molds: [] # source element for data-each clone, to be deleted from final rendering

  constructor: (node, context) ->
    @push context if context
    if node.nodeType == window.Node.ELEMENT_NODE # TODO: is this check needed?
      attr = node.attributes # node.dataset not supported by jsdom

      if value = attr['data-if']?.value
        unless @resolve value
          @molds.push node
          return

      if value = attr['data-unless']?.value
        if @resolve value
          @molds.push node
          return

      if value = attr['data-each']?.value
        [iterables, item] = value.split ' '
        for obj in (@resolve iterables) or []
          node.removeAttribute 'data-each'
          node.parentNode.insertBefore clone = node.cloneNode(true)
          context = {}
          context[item] = obj
          @constructor clone, context
        @molds.push node
        return

      # non-destructive

      if value = attr['data-attr']?.value
        [attr, keypath] = value.split ' '
        node.setAttribute attr, (@resolve keypath)  ? ''

      if value = attr['data-style']?.value
        for item in value.split ', '
          [attr, keypath] = item.split ' '
          node.style[attr] = (@resolve keypath ? '')

      if value = attr['data-class']?.value
        for item in value.split ', '
          [cls, keypath] = item.split ' '
          if not keypath
            result = @resolve cls # use cls as keypath
            if result instanceof Array
              node.classList.add cls for cls in result
            else if typeof(result) == 'object'
              for cls, bool of result
                node.classList[bool and 'add' or 'remove'] cls
            else
              node.classList.add result
          else
            node.classList[(@resolve keypath) and 'add' or 'remove'] cls

      if value = attr['data-route']?.value
        [viewpath, params...] = value.split ' '
        params = params.map @resolve.bind @
        route = @resolve viewpath
        path = route.reverse params
        navigate = (@get 'navigate')
        node.addEventListener 'click', (event) =>
          event.preventDefault()
          navigate path
        , true
        node.setAttribute 'href', path if node.tagName == 'A'

      if value = attr['data-event']?.value
        [name, keypath, args...] = value.split ' '
        args = args.map (arg) => @resolve arg
        handler = @resolve keypath
        cb = (event) =>
          if name == 'submit' # serialize form
            event.preventDefault()
            form = event.target
            data = {}
            data[node.name] = node.value for node in form.elements when node.name
            handler data, args..., event
          else
            handler args..., event
        node.addEventListener name, cb, true

      if keypath = attr['data-text']?.value
        node.textContent = (@resolve keypath) ? ''

      else if keypath = attr['data-html']?.value
        node.innerHTML = (@resolve keypath) ? ''

      else
        @constructor child for child in node.childNodes

    @pop() if context
    mold.parentNode.removeChild mold while mold = @molds.pop()

exports = module.exports = Renderer
