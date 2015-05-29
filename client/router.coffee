# the entry point to this application happens from the router. After that, 
# everything is managed through the controller and the routes are just
# so you can copy paste and get to the same place.
start = R.once(R.call)

FlowRouter.route '/welcome', 
  action: (params, queryParams) ->
    start -> app.controller.welcome.appear()

FlowRouter.route '/', 
  action: (params, queryParams) ->
    start -> app.controller.lists.appear()

FlowRouter.route '/list/:_id', 
  action: (params, queryParams) ->
    start -> app.controller.list.appear(params._id)

