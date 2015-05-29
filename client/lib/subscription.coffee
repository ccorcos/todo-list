
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
      f()
    else
      Meteor.clearTimeout(id)

insertBeforeWhere = (insert, where, list) ->
  inserted = false
  newList = R.reduce((acc,item) ->
    if where(item)
      inserted = true
      return R.concat(acc, [insert, item])
    else
      return R.concat(acc, [item])
  ), [], list)
  unless inserted
    newList = R.append(insert, list)
  return newList

observeChanges = (cursor, callbacks) ->
  first = true
  initialDocs = []
  handle = cursor.observeChanges 
    addedBefore: (id, fields, before) ->
      if first
        doc = R.merge(fields, {_id:id})
        initialDocs = insertBeforeWhere(doc, R.propEq('_id', before), initialDocs)
      else
        callbacks.addedBefore(id, fields)
    changed: (id, fields) ->
      callbacks.changed(id, fields)
    removed: (id) ->
      callbacks.removed(id)
  callbacks.initial(initialDocs)
  first = false
  initialDocs = null
  return handle



# calls startLoading, stopLoading, intial, added, changed, removed, subscribe, cursor, onReset, onStart, onStop
class Subscription
  constructor: (obj) ->
    _.extend(this, obj,{
      handles: []
      timeout: null
    })
  reset: ->
    @stopHandles()
    @onReset?()
    R.map(R.invoke('onReset', []), @cursors)
  stopHandles: ->
    R.map(R.invoke('stop', []), @handles)
    @handles = []
  stop: ->
    @timeout = Meteor.setTimeout(@reset.bind(this), 1000*60*2)
    @onStop?()
    R.map(R.invoke('onStop', []), @cursors)
  start: ->
    @onStart?()
    R.map(R.invoke('onStart', []), @cursors)
    Meteor.clearTimeout(@timeout)
    undo = callDelayUndoCancel(100, @startLoading)
    # subscribe to data from the server
    @handles.push @subscribe =>
      undo(@stopLoading)
      # reactively watch for events and animate the UI accordingly
      if @cursor
        @handles.push observeChanges(@cursor(), R.pick(['initial', 'added', 'changed', 'removed'], this))
      else if @cursors
        for cursor in @cursors
          @handles.push observeChanges(cursor.cursor(), R.pick(['initial', 'added', 'changed', 'removed'], cursor))

_.extend(this, {insertBeforeWhere, Subscription})