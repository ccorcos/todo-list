# the lists page. just a list of events
app.views.listItem = React.createClassFactory
  displayName: 'ListItem'
  mixins: [
    React.addons.PureRenderMixin
  ]
  propTypes:
    list: React.PropTypes.object.isRequired
    onClick: React.PropTypes.func
  render: ->
    {div} = React.DOM
    (div {
        className: 'list-item', 
        onClick: this.props.onClick
      },
      (div {className: 'title', ref:'title'}, this.props.list.title)
      (div {className: 'unchecked', ref:'unchecked'}, this.props.list.unchecked)
    )


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
    {listItem} = app.views
    (listItem {
        key: list._id, 
        ref: list._id
        list: list
        onClick: -> app.controller.lists.segueToList(list._id)
      })
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
  cursors: [{
    cursor: ->
      Lists.find({}, {sort: {title: -1}})
    initial: (lists) ->
      # animate initial events in
      enqueueAnimation 'lists', (done) ->
        # only animate in the new events
        newLists = differenceWhere(R.prop('_id'), lists, app.state.lists.lists)
        updateState({lists: {lists: lists}})
        render ->
          animate(listsRefs(newLists), 'transition.slideUpIn', {stagger:100}, done)
    addedBefore: (id, list, before) ->
      list = R.merge(list, {_id:id})
      enqueueAnimation 'lists', (done) ->
        refs = listsRefs([list])
        evolveState({lists: {lists: insertBeforeWhere(list, R.propEq('_id', before), app.state.lists.lists)}})
        render ->
          # set opacity 0
          hideRefs(refs) 
          # animate height from 0 to 100 percent assuming its hidden
          animate refs, {height:['100%', '0%']}, {}, -> 
            # then slide it in nicely
            animate refs, 'transition.fadeIn', {}, done
    changed: (id, fields) ->
      enqueueAnimation 'lists', (done) ->
        refs =  R.map(R.concat("lists.#{id}."), R.keys(fields))
        animate refs, 'transition.fadeOut', {}, ->
          evolveState({lists: {lists: evolveWhere(R.propEq('_id', id), R.merge(fields))}})
          render ->
            animate refs, 'transition.fadeIn', {}, done
    removed: (id) ->
      # remove a document
      enqueueAnimation 'lists', (done) ->
        animate listsRefs([{_id: id}]), {height:0, opacity:0}, {}, -> 
          evolveState({lists: {lists: R.filter(R.complement(R.propEq('_id', id)))}})
          render(done)
  }],
  loadMore: () ->
    @stopHandles()
    @limit += @inc
    @start()
  onReset: () ->
    @limit = @initialLimit
    app.state.lists.lists = []
}

# initial state
initialState({lists:{isLoading:false, lists:[]}})

app.animations.lists = {
  appear: (done) ->
    app.subscriptions.lists.start()
    updateState({route:'lists', lists:{isLoading:false}})
    render ->
      complete = nthCallOf(2, done)
      animate(['lists.header'], 'transition.fadeIn', {}, complete)
      animate(listsRefs(app.state.lists.lists), 'transition.fadeIn', {}, complete)
}

app.controller.lists = {
  appear: ->
    enqueueAnimation('appear', app.animations.lists.appear)
      
  segueToLogout: ->
    enqueueAnimation 'transition', (done) ->
      # stop all subscription now
      app.resetSubscriptions()
      app.resetState()
      Meteor.logout()
      animate ['lists'], 'transition.fadeOut', {}, ->
        app.animations.welcome.appear(done)

  segueToNewList: ->

  segueToList: (listId) ->
    enqueueAnimation 'transition', (done) ->
      # stop all subscription now
      app.subscriptions.lists.stop()
      updateState({list:{list: R.find(R.propEq('_id', listId), app.state.lists.lists), items:Items.find({listId}).fetch()}})
      animate ['lists'], 'transition.fadeOut', {}, ->
        FlowRouter.go("/list/#{listId}")
        app.animations.list.appear(listId, done)

}