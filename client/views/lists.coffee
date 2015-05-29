
# the lists page. just a list of events
app.views.lists = React.createClassFactory
  displayName: 'Lists'
  mixins: [
    React.addons.PureRenderMixin
    RegisterRefMixin('lists')
  ]
  propTypes:
    isLoading: React.PropTypes.bool.isRequired
    lists: React.PropTypes.array.isRequired
  renderList: (list) ->
    {div} = React.DOM
    (div {
        className: 'list-item', 
        key: list._id, 
        ref: list._id
        onClick: -> app.controller.lists.segueToList(list._id)
      },
      (div {className: 'title', ref:'title'}, list.title)
      (div {className: 'unchecked', ref:'unchecked'}, list.unchecked)
    )
  render: ->
    {div} = React.DOM
    
    (div {className: 'body'},
      (div {className: 'header', ref: 'header'},
        (div {className: 'left logout', onClick: app.controller.lists.segueToLogout}, "logout")
        (div {className: 'title'}, "Todo Lists")
        (div {className: 'right new-list', onClick: app.controller.lists.segueToNewList}, "new list")
      )
      R.map(@renderList, @props.lists)
      do =>
        if this.props.isLoading
          (div {ref:'loading', className:'loading'}, "loading...")
    )


listsRefs = R.map(R.compose(
  R.concat('lists.')
  R.prop('_id')
))

app.subscriptions.lists = new Subscription {
  limit: 10
  initialLimit: 10
  inc: 5
  subscribe: (onReady) ->
    Meteor.subscribe('lists', @limit, onReady)
  cursor: ->
    Lists.find({}, {sort: {title: -1}})
  startLoading: ->
    enqueueAnimation 'lists', (done) ->
      updateState({lists: {isLoading: true}})
      render ->
        animate ['lists.loading'], 'transition.fadeIn', done
  stopLoading: ->
    enqueueAnimation 'lists', (done) ->
      updateState({lists: {isLoading: false}})
      render ->
        animate ['lists.loading'], 'transition.fadeOut', done  
  initial: (lists) ->
    # animate initial events in
    enqueueAnimation 'lists', (done) ->
      # only animate in the new events
      newLists = R.difference(lists, app.state.lists.lists)
      updateState({lists: {lists: lists}})
      render ->
        animate(listsRefs(newLists), 'transition.slideUpIn', done)
  addedBefore: (id, list, before) ->
    list = R.merge(list, {_id:id})
    enqueueAnimation 'lists', (done) ->
      refs = listsRefs([list])
      evolveState({lists: {lists: insertBeforeWhere(list, R.propEq('_id', before))}})
      render ->
        # set opacity 0
        hideRefs(refs) 
        # animate height from 0 to 100 percent assuming its hidden
        animate refs, {height:['100%', '0%']}, -> 
          # then slide it in nicely
          animate refs, 'transition.fadeIn', {}, done
  changed: (id, fields) ->
    enqueueAnimation 'lists', (done) ->
      refs =  R.map(R.concat("lists.#{id}."), R.keys(fields))
      animate refs, 'transition.fadeOut', {}, ->
        evolveState({lists: {lists: evolveWhere(R.propEq('_id', id), R.merge(fields))}})
        render ->
          animate refs, 'transition.fadeIn', done
  removed: (id) ->
    # remove a document
    enqueueAnimation 'lists', (done) ->
      animate refs, {height:['100%', '0%'], opacity: 0}, -> 
        evolveState({lists: {lists: R.filter(R.complement(R.propEq('_id', id)))}})
        render(done)
  loadMore: () ->
    @stopHandles()
    @limit += @inc
    @start()
  onReset: () ->
    @limit = @initialLimit
    app.state.lists.lists = []
}

# initial state
updateState({lists:{isLoading:false, lists:[]}})

app.animations.lists = {
  appear: (done) ->
    app.subscriptions.lists.start()
    updateState({route:'lists', lists:{isLoading:false}})
    render ->
      animate(['lists.header'], 'transition.slideDownIn', {}, done)
}

app.controller.lists = {
  appear: ->
    enqueueAnimation('appear', app.animations.lists.appear)
      
  segueToLogout: ->
    enqueueAnimation 'transition', (done) ->
      # stop all subscription now
      R.map(R.invoke('reset', []), app.subscriptions)
      Meteor.logout()
      animate ['lists'], 'transition.fadeOut', {}, ->
        app.animations.welcome.appear(done)

  segueToNewList: ->

  segueToList: (listId) ->
    enqueueAnimation 'transition', (done) ->
      # stop all subscription now
      app.subscriptions.lists.stop()
      animate ['lists'], 'transition.fadeOut', {}, ->
        app.animations.list.appear(listId, done)

}