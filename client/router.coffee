# the entry point to this application happens from the router. After that, 
# everything is managed through the controller and the routes are just
# so you can copy paste and get to the same place.
start = R.once(R.call)

loginRequired = (path, next) ->
  if Meteor.userId()
    next()
  else
    next('/welcome')

logoutRequired = (path, next) ->
  if Meteor.userId()
    next('/')
  else
    next()

FlowRouter.route '/welcome', 
  middlewares: [logoutRequired]
  action: (params, queryParams) ->
    start -> 
      app.resetState()
      app.controller.welcome.appear()

FlowRouter.route '/', 
  middlewares: [loginRequired]
  action: (params, queryParams) ->
    start -> 
      app.resetState()
      app.controller.lists.appear()

FlowRouter.route '/list/:_id', 
  middlewares: [loginRequired]
  action: (params, queryParams) ->
    start -> 
      app.resetState()
      app.controller.list.appear(params._id)

