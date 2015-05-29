
differenceWhere = (func, list1, list2) ->
  R.filter((R.complement((x1) -> 
    R.find(((x2) -> 
      R.eq(func(x1), func(x2))
    ), list2)
  )), list1) 


# Call the func after some number of ms unless canceled.
# when canceled, the function will run if the func has been run
# thus und
callDelayUndoCancel = (ms, func) ->
  called = false
  id = Meteor.setTimeout(->
    called = true
    func()
  , ms)
  (f) -> 
    if called
      f?()
    else
      Meteor.clearTimeout(id)

_.extend(this, {differenceWhere, callDelayUndoCancel})