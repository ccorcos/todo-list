strangle = (x, maxMin) ->
  x = Math.max(x, maxMin[0])
  x = Math.min(x , maxMin[1])
  return x

# the feed page. just a list of events
app.views.item = React.createClassFactory
  displayName: 'Item'
  mixins: [
    React.addons.PureRenderMixin
  ]
  propTypes:
    item: React.PropTypes.object.isRequired
  

  render: ->
    {div, input} = React.DOM

    (div {className: 'list-item'},
      (div {className: 'title', ref:'title'}, this.props.item.title)
      (input {
        type: 'checkbox', 
        ref:'checked',
        checked:this.props.item.checked
        onChange: (e) =>
          Meteor.call('setItemChecked', this.props.item._id, e.target.checked)
      })
    )

# the feed page. just a list of events
app.views.list = React.createClassFactory
  displayName: 'List'
  mixins: [
    React.addons.LinkedStateMixin
    React.addons.PureRenderMixin
    RegisterRefMixin('list')
  ]
  propTypes:
    isLoading: React.PropTypes.bool.isRequired
    list: React.PropTypes.object.isRequired
    items: React.PropTypes.array.isRequired

  
  getInitialState: ->
    newItem: ''
    title: this.props.list.title or ''

  componentWillReceiveProps: (props) ->
    if props.list.title
      @setState({title:props.list.title})

  renderItem: (listItem) ->
    {item} = app.views
    (item {item: listItem, key:listItem._id, ref: listItem._id})

  handleTitleTabOrReturn: (e) ->
    if e.key is "Tab" or e.key is "Enter"
      e.preventDefault()
      $ref('list.title').blur()

  setTitle: ->
    if @state.title isnt @props.list.title
      updateState({list:{list:{title:@state.title}}})
      Meteor.call('setListTitle', @props.list._id, @state.title)

  handleItemTabOrReturn: (e) ->
    if e.key is "Tab" or e.key is "Enter"
      e.preventDefault()
      $ref('list.newItem').blur()

  submitNewItem: () ->
    if @state.newItem.length > 0
      app.controller.list.newItem(@state.newItem)
      @setState({newItem:''})


  render: ->
    {div, input} = React.DOM
    
    (div {className: 'body'},
      (div {className: 'header', ref: 'header'},
        (div {className: 'left back', onClick: app.controller.list.segueToLists}, "back")
        (input {
          type:'text'
          ref: 'title'
          className: 'title'
          valueLink: @linkState('title'), 
          placeholder:'todo list title', 
          onBlur: @setTitle, 
          onKeyDown:@handleTitleTabOrReturn
        })
      )
      (input {type:'text', className: 'new-item', ref:'newItem', valueLink: @linkState('newItem'), placeholder:'new todo item', onBlur: @submitNewItem, onKeyDown:@handleItemTabOrReturn})
      R.map(@renderItem, @props.items)
      do =>
        if this.props.isLoading
          (div {ref:'loading', className:'loading'}, "loading...")
    )

listRefs = R.map(R.compose(
  R.concat('list.')
  R.prop('_id')
))

createListSubscription = (listId) ->
  new Subscription 
    subscribe: (onReady) ->
      Meteor.subscribe('list', listId, onReady)
    startLoading: ->
      enqueueAnimation 'list', (done) ->
        updateState({list: {isLoading: true}})
        render ->
          animate ['list.loading'], 'transition.fadeIn', done
    stopLoading: ->
      enqueueAnimation 'list', (done) ->
        updateState({list: {isLoading: false}})
        render ->
          animate ['list.loading'], 'transition.fadeOut', done  
    cursors: [{
      cursor: ->
        Items.find({listId}, {sort: {title: -1}})
      initial: (items) ->
        # animate initial events in
        enqueueAnimation 'list', (done) ->
          # only animate in the new events
          newItems = differenceWhere(R.prop('_id'), items, app.state.list.items)
          updateState({list: {items: items}})
          render ->
            animate(listRefs(newItems), 'transition.slideUpIn', {stagger:50}, done)

      addedBefore: (id, item, before) ->
        item = R.merge(item, {_id:id})
        enqueueAnimation 'list', (done) ->
          refs = listRefs([item])
          evolveState({list: {items: insertBeforeWhere(item, R.propEq('_id', before))}})
          render ->
            # set opacity 0
            hideRefs(refs) 
            # animate height from 0 to 100 percent assuming its hidden
            animate refs, 'transition.fadeIn', {}, done
      changed: (id, fields) ->
        enqueueAnimation 'list', (done) ->
          refs =  R.map(R.concat("list.#{id}."), R.keys(fields))
          animate refs, 'transition.slideRightOut', {duration:100}, ->
            evolveState({list: {items: updateWhere(R.propEq('_id', id), R.merge(R.__, fields))}})
            render ->
              animate(refs, 'transition.slideLeftIn', {duration:100}, done)
      removed: (id) ->
        # remove a document
        enqueueAnimation 'list', (done) ->
          animate refs, {height:['100%', '0%'], opacity: 0}, -> 
            evolveState({list: {items: R.filter(R.complement(R.propEq('_id', id)))}})
            render(done)
      onReset: () ->
        app.state.list.items = []
    }, {
      cursor: ->
        Lists.find(listId)
      initial: ([list]) ->
        # animate initial events in
        enqueueAnimation 'list', (done) ->
          animateOut = (next) ->
            animate ['list.title'], 'transition.fadeOut', {}, next
          animateIn = (next) ->
            animate ['list.title'], 'transition.fadeIn', {}, next

          if app.state.list.list.title isnt list.title
            if app.state.list.list.title
              animateOut ->
                updateState({list: {list: list}})
                render ->
                  animateIn(done)
            else
              updateState({list: {list: list}})
              render ->
                animateIn(done)
          else
            done()
      addedBefore: (id, item, before) ->
      changed: (id, fields) ->
        if fields.title and (fields.title isnt app.state.list.list.title)
          enqueueAnimation 'list', (done) ->
            animateOut = (next) ->
              animate ['list.title'], 'transition.fadeOut', {}, next
            animateIn = (next) ->
              animate ['list.title'], 'transition.fadeIn', {}, next
            
            animateOut ->
              updateState({list: {list: {title: fields.title}}})
              render ->
                animateIn(done)
      removed: (id) ->
    }]

app.subscriptions.list = {
  cache: {}
  current: null
  start: (listId) ->
    sub = @cache[listId]
    if sub
      sub.start()
      @current = sub
    else
      sub = createListSubscription(listId)
      sub.start()
      @cache[listId] = sub
      @current = sub
  stop: ->
    @current?.stop?()
    @current = null
    updateState({
      list: {list:{}, items:[]}  
    })
  reset: ->
    R.map(R.invoke('reset', []), R.values(@cache))
    @cache = {}
    @current = null
}

# initial state
initialState({list:{isLoading:false, list:{}, items:[]}})
  
app.animations.list = {
  appear: R.curry (listId, done) ->
    app.subscriptions.list.start(listId)
    updateState({route:'list', list:{isLoading:false}})
    render ->
      complete = nthCallOf(2, done)
      animate(['list.header'], 'transition.fadeIn', {}, complete)
      animate(listRefs(app.state.list.items), 'transition.fadeIn', {}, complete)
}

app.controller.list = {
  appear: (listId) ->
    enqueueAnimation('appear', app.animations.list.appear(listId))
      
  segueToLists: () ->
    enqueueAnimation 'transition', (done) ->
      # stop all subscription now
      app.subscriptions.list.stop()
      animate ['list'], 'transition.fadeOut', {}, ->
        FlowRouter.go('/')
        app.animations.lists.appear(done)

  newItem: (title) ->
    listId = app.state.list.list._id    
    Meteor.call('newItem', listId, title)
}