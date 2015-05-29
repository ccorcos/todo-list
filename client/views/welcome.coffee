
app.views.welcome = React.createClassFactory
  displayName: 'Welcome'

  mixins: [
    React.addons.LinkedStateMixin
    React.addons.PureRenderMixin
    RegisterRefMixin('welcome')
  ]

  propTypes:
    scene: React.PropTypes.oneOf(['username', 'login', 'signup', 'loading']).isRequired
    error: React.PropTypes.string.isRequired

  getInitialState: ->
    username: ''
    email:    ''
    password: ''
    verify:   ''

  submitUsername: (e) ->
    e.preventDefault()
    @checkUsername()

  checkUsername: ->
    username = @state.username
    if username.length is 0 then return
    Meteor.call "usernameExists", username, (err, exists) =>
      if exists
        app.controller.welcome.segueToLogin()
      else
        app.controller.welcome.segueToSignup()

  submitSignup: (e) ->
    e.preventDefault()
    @signup()

  signup: () ->
    app.controller.welcome.signup(@state.username, @state.email, @state.password, @state.verify)

  submitLogin: (e) ->
    e.preventDefault()
    @login()

  login: ->
    app.controller.welcome.login(@state.username, @state.password)

  changeUsername: () ->
    app.controller.welcome.segueToUsername()

  handleTabKey: (e) ->
    if e.key is "Tab"
      # we have to prevent default in order to
      # focus immediately on th next one.
      e.preventDefault()
      $ref('welcome.username').blur()

  scenes:
    'username': ->
      {div, form, input} = React.DOM
      (div {className:'body'},
        (div {className: 'welcome', ref: 'banner'}, "Welcome")
        (form {onSubmit: @submitUsername},
          (input {type:'text', placeholder:'username', ref: 'username', valueLink: @linkState('username'), onBlur: @checkUsername, onKeyDown:@handleTabKey})
        )
      )
    'signup': ->
      {div, form, input} = React.DOM
      (div {className:'body'},
        (div {className: 'welcome', ref: 'banner'}, "Welcome")
        (form {onSubmit: @submitSignup},
          (input {type:'text',     placeholder:'username', ref: 'username', valueLink: @linkState('username'), onFocus: @changeUsername})
          (input {type:'text',     placeholder:'email',    ref: 'email',    valueLink: @linkState('email')})
          (input {type:'password', placeholder:'password', ref: 'password', valueLink: @linkState('password')})
          (input {type:'password', placeholder:'verify',   ref: 'verify',   valueLink: @linkState('verify')})
          (input {type:'submit', style: {opacity:0, height:0, position:'absolute'}})
        )
        (div {className:'error', ref: 'error'}, @props.error)
      )
    'login': ->
      {div, form, input} = React.DOM
      (div {className:'body'},
        (div {className: 'welcome', ref: 'banner'}, "Welcome")
        (form {onSubmit: @submitLogin},
          (input {type:'text',     placeholder:'username', ref: 'username', valueLink: @linkState('username'), onFocus: @changeUsername})
          (input {type:'password', placeholder:'password', ref: 'password', valueLink: @linkState('password')})
          (input {type:'submit', style: {opacity:0, height:0, position:'absolute'}})
        )
        (div {className:'error', ref: 'error'}, @props.error)
      )
    'loading': ->
      {div, form, input} = React.DOM
      (div {className:'body'},
        (div {className: 'welcome', ref: 'banner'},
          "Welcome"
          (div {className: 'loading', ref: 'loading'}, "loading...")
        )
      )

  render: ->
    @scenes[@props.scene].bind(this)()


app.animations.welcome = {
  appear: (done) ->  
    updateState({
      route: 'welcome'
      welcome:
        scene: 'username'
        error: ''
    })
    complete = nthCallOf(2, done)
    render ->
      animate(['welcome.banner'], 'transition.fadeIn', {}, complete)
      animate(['welcome.username'], 'transition.slideUpIn', {}, complete)
  disappear: (done) ->
    animate([
      'welcome.banner'
      'welcome.username'
      'welcome.email'
      'welcome.password'
      'welcome.verify'
      'welcome.error'
      'welcome.loading'
    ], 'transition.fadeOut', {}, done)
}

app.controller.welcome = 
  appear: -> 
    enqueueAnimation('appear', app.animations.welcome.appear)

  segueToUsername: ->
    animateOut = (next) ->
      complete = nthCallOf(2, next)
      $ref('welcome.username').focus()
      animate(['welcome.error'], 'transition.slideDownOut', {}, complete)
      animate([
        'welcome.verify'
        'welcome.password'
        'welcome.email'
      ], 'transition.slideDownOut', {stagger:100}, complete)

    animation = (done) ->
      updateState({
        route: 'welcome'
        welcome:
          scene: 'username'
          error: ''
      })
      animateOut ->
        render(done)

    enqueueAnimation('welcome', animation)

  segueToLogin: ->
    animation = (done) ->
      updateState({
        route: 'welcome'
        welcome:
          scene: 'login'
          error: ''
      })
      render ->
        $ref('welcome.password').focus()
        animate(['welcome.password'], 'transition.slideUpIn', {}, done)

    enqueueAnimation('welcome', animation)


  segueToSignup: ->
    animation = (done) ->
      updateState({
        route: 'welcome'
        welcome:
          scene: 'signup'
          error: ''
      })
      render ->
        $ref('welcome.email').focus()
        animate(['welcome.email', 'welcome.password', 'welcome.verify'], 'transition.slideUpIn', {stagger: 100}, done)

    enqueueAnimation('welcome', animation)

  startLoading: () ->
    animateOut = (next) ->
      animate([
        'welcome.username'
        'welcome.email'
        'welcome.password'
        'welcome.verify'
        'welcome.error'
      ], 'transition.fadeOut', {}, ->
        next()
      )

    animation = (done) ->
      console.log "start loading"
      updateState({
        route: 'welcome'
        welcome:
          scene: 'loading'
          error: ''
      })
      animateOut ->
        render ->
          animate(['welcome.loading'], 'transition.fadeIn', {}, done)

    enqueueAnimation('welcome', animation)

  segueLoginFail: (errMsg) ->

    animation = (done) ->
      updateState({
        route: 'welcome'
        welcome:
          scene: 'login'
          error: errMsg
      })
      if app.state.welcome.isLoading
        animate ['welcome.loading'], 'transition.fadeOut', {}, ->
          render ->
            animate([
              'welcome.username'
              'welcome.password'
              'welcome.error'
            ], 'transition.fadeIn', {}, done)
      else
        animate ['welcome.error'], 'transition.fadeOut', {}, ->
          render ->
            animate([
              'welcome.error'
            ], 'transition.fadeIn', {}, done)

    enqueueAnimation('welcome', animation)

  segueSignupFail: (errMsg) ->
    animation = (done) ->
      updateState({
        route: 'welcome'
        welcome:
          scene: 'signup'
          error: errMsg
      })
      if app.state.welcome.isLoading
        animate ['welcome.loading'], 'transition.fadeOut', {}, ->
          render ->
            animate([
              'welcome.username'
              'welcome.email'
              'welcome.password'
              'welcome.verify'
              'welcome.error'
            ], 'transition.fadeIn', {}, done)
      else
        animate ['welcome.error'], 'transition.fadeOut', {}, ->
          render ->
            animate([
              'welcome.error'
            ], 'transition.fadeIn', {}, done)

    enqueueAnimation('welcome', animation)

  errorSegue: (errMsg) ->
    animateIn = (next) ->
      animate(['welcome.error'], 'transition.fadeIn', {}, next)
    animateOut = (next) ->
      animate(['welcome.error'], 'transition.fadeOut', {}, next)
    animation = (done) ->
      if errMsg is app.state.welcome.error
        done()
      else
        updateState({
          welcome:
            error: errMsg
        })
        if app.state.welcome.error and errMsg
          animateOut ->
            render ->
              animateIn(done)
        else if app.state.welcome.error and not errMsg
          animateOut ->
            render(done)
        else if not app.state.welcome.error and errMsg
          render ->
            animateIn(done)
        else
          console.warn "shouldn't ever get here..."
          done()

    enqueueAnimation('welcome', animation)

  signup: (username, email, password, verify) ->
    if email is ''
      @errorSegue("What's your email?")
      return

    if password is ''
      @errorSegue("What's you password?")
      return

    if password isnt verify
      @errorSegue("Passwords don't match")
      return

    undo = callDelayUndoCancel(1000, @startLoading.bind(this))
    Accounts.createUser {username: username, password: password, email: email}, (err) =>
      undo()
      if err
        @segueSignupFail(err.reason)
      else
        app.controller.welcome.segueToLists()

  login: (username, password) ->
    if password is ''
      @errorSegue("What's you password?")
      return

    undo = callDelayUndoCancel(1000, @startLoading.bind(this))
    Meteor.loginWithPassword username, password, (err) =>
      undo()
      if err
        @segueLoginFail(err.reason)
      else
        app.controller.welcome.segueToLists()

  segueToLists: ->
    enqueueAnimation 'transition', (done) ->
      app.animations.welcome.disappear ->
        app.animations.lists.appear(done)