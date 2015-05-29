
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

updateState = (obj) ->
  app.state = R.clone(app.state)
  extend(app.state, obj)

evolveState = (obj) ->
  app.state = R.clone(app.state)
  evolve(app.state, obj)

initialStates = []
initialState = (obj) ->
  initialStates.push(obj)

app.resetState = ->
  app.state = R.reduce(extend, {}, initialStates)


_.extend(this, {
  render
  updateState
  evolveState
  initialState
})
