

insertBeforeWhere = (insert, where, list) ->
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


callMethod = R.curry (name, obj) ->
  obj[name]?()

# calls startLoading, stopLoading, subscribe, cursors: cursor, intial, added, changed, removed, onReset, onStart, onStop
class Subscription
  constructor: (obj) ->
    _.extend(this, obj,{
      handles: []
      timeout: null
    })
  reset: ->
    @stopHandles()
    @onReset?()
    R.map(callMethod('onReset'), @cursors)
  stopHandles: ->
    R.map(R.invoke('stop', []), @handles)
    @handles = []
  stop: ->
    @timeout = Meteor.setTimeout(@reset.bind(this), 1000*60*2)
    @onStop?()
    R.map(callMethod('onStop'), @cursors)
  start: ->
    @onStart?()
    R.map(callMethod('onStart'), @cursors)
    Meteor.clearTimeout(@timeout)
    undo = callDelayUndoCancel(100, @startLoading)
    # subscribe to data from the server
    @handles.push @subscribe =>
      undo(@stopLoading)
      # reactively watch for events and animate the UI accordingly
      for cursor in @cursors
        @handles.push observeChanges(cursor.cursor(), R.pick(['initial', 'added', 'changed', 'removed'], cursor))

_.extend(this, {insertBeforeWhere, Subscription})