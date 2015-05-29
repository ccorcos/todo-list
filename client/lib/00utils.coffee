
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

insertBeforeWhere = R.curry (insert, where, list) ->
  inserted = false
  newList = R.reduce( ((acc,item) ->
    if where(item)
      inserted = true
      return R.concat(acc, [insert, item])
    else
      return R.concat(acc, [item])
  ), [], list)
  unless inserted
    newList = R.append(insert, list)
  return newList


extend = R.curry (dest, obj) ->
  for k,v of obj
    if _.isPlainObject(v)
      unless dest[k]
        dest[k] = {}
      # recursively extend nested objects
      extend(dest[k], v)
    else
      dest[k] = v
  return dest


evolve = R.curry (dest, obj) ->
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
  return dest

    
updateWhere = R.curry (pred, fn, list) ->
  R.map (elm) ->
    if pred(elm)
      fn(elm)
    else
      elm
  , list

evolveWhere = R.curry (pred, evolution, list) ->
  updateWhere(pred, evolve(R.__, evolution), list)


_.extend(this, {insertBeforeWhere, differenceWhere, callDelayUndoCancel, extend, evolve, updateWhere, evolveWhere})
