



observeChanges = (cursor, callbacks) ->
  initialDocs = []
  first = true
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
      observers: []
      subs: []
      timeout: null
    })
  reset: ->
    @stopHandles()
    @onReset?()
    R.map(callMethod('onReset'), @cursors)
  stopHandles: ->
    R.map(R.invoke('stop', []), @observers)
    R.map(R.invoke('stop', []), @subs)
    @subs = []
    @observers = []
  stop: ->
    @timeout = Meteor.setTimeout(@reset.bind(this), 1000*60*2)
    @onStop?()
    R.map(R.invoke('stop', []), @observers)
    R.map(callMethod('onStop'), @cursors)
  start: ->
    @onStart?()
    R.map(callMethod('onStart'), @cursors)
    Meteor.clearTimeout(@timeout)
    # start sub if it hasnt been or restart cursors
    if @subs.length is 0
      undo = callDelayUndoCancel(100, @startLoading)
      # subscribe to data from the server
      @subs.push @subscribe =>
        undo(@stopLoading)
        # reactively watch for events and animate the UI accordingly
        for cursor in @cursors
          @observers.push observeChanges(cursor.cursor(), R.pick(['initial', 'addedBefore', 'changed', 'removed'], cursor))
    else
      # reactively watch for events and animate the UI accordingly
      for cursor in @cursors
        @observers.push observeChanges(cursor.cursor(), R.pick(['initial', 'addedBefore', 'changed', 'removed'], cursor))


app.resetSubscriptions = ->
  R.map(R.invoke('reset', []), R.values(app.subscriptions))

_.extend(this, {Subscription})