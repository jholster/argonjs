class Route
  constructor: (@pattern, @view) ->
    re_str = @pattern
      .replace(/\?/g, '([^/]+)') # ? matches a single path component, i.e. anything between //
      .replace(/\*/g, '(.*)')    # * matches anything, i.e. including /
    @re = new RegExp "^#{re_str}$"

  reverse: (params) ->
    @pattern.replace /[\?\*]/, -> params.shift()

  match: (url) ->
    params.slice 1 if params = url.match @re

exports = module.exports = Route
