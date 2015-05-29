
App = React.createClassFactory
  displayName: 'App'
  mixins: [] # not pure because app.state is mutable
  render: ->
    route = this.props.route
    view = app.views[route]
    props = app.state[route]
    view(props)

render = (done) ->
  React.render(App(app.state), document.body, done)

extend = (dest, obj) ->
  for k,v of obj
    if _.isPlainObject(v)
      unless dest[k]
        dest[k] = {}
      # recursively extend nested objects
      extend(dest[k], v)
    else
      dest[k] = v

updateState = R.curry(extend)(app.state)

evolve = (dest, obj) ->
  for k,v of obj
    if _.isPlainObject(v)
      unless dest[k]
        dest[k] = {}
      # recursively extend nested objects
      evolve(dest[k], v)
    else if _.isFunction(v)
      dest[k] = v(dest[k])
    else
      dest[k] = v

evolveState = R.curry(evolve)(app.state)

evolveWhere = R.curry (where, evolve, list) ->
  R.map(R.cond([
    [where, evolve]
    [R.T, R.identity]
  ]), list)

_.extend(this, {
  render
  updateState
  evolveState
  evolveWhere
})
