animation$ = flyd.stream()

beginBusy = (busyAnimation, animation, action, state) ->
  R.and(R.whereEq({type: 'begin', animation: animation}, action),
        R.path([busyAnimation, 'busy'], state))

busyEnd = (busyAnimation, action) ->
  R.whereEq({type: 'end', animation: busyAnimation}, action)

startAnimation = (animation, func) ->
  func -> animation$({type: 'end', animation})

consumeAction = ({action, state}) -> {action: {}, state: state}

# set the next animation
setNext = (animation, func, data) ->
  R.assocPath(['state', animation, 'next'], func, data)

# run and drop the next animation
startNext = (animation, state) ->
  nextFunc = state[animation].next
  if nextFunc
    startAnimation(animation, nextFunc)
    state[animation].busy += 1
    R.assocPath([animation, 'next'], null)(state)
  else
    state

# append an animation function to the queue
enqueue = (animation, func, data) ->
  # could be better if Ramda was better at nested objects
  newQueue = R.append(func, data.state[animation].queue)
  R.evolve({state: R.assocPath([animation, 'queue'], newQueue)}, data)

# run and drop the firt queued animation
dequeue = (animation, state) ->
  nextFunc = R.head(state[animation].queue)
  if nextFunc 
    state[animation].busy += 1
    startAnimation(animation, nextFunc)
    newQueue = R.tail(state[animation].queue)
    return R.assocPath([animation, 'queue'], newQueue, state)
  else
    return state
  

# drop the action if an animation is busy
dropOn = R.curry (busyAnimation, animation, {action, state}) ->
  if beginBusy(busyAnimation, animation, action, state)
    consumeAction({action, state})
  else
    {action, state}

# queueLatest an animation if another animation is busy
queueLatestOn = R.curry (busyAnimation, animation, {action, state}) ->
  if beginBusy(busyAnimation, animation, action, state)
    consumeAction(setNext(animation, action.func, {action, state}))
  else if busyEnd(busyAnimation, action)
    {action, state: startNext(animation, state)}
  else
    {action, state}

# queue all animations if another animation is busy
queueAllOn = R.curry (busyAnimation, animation, {action, state}) ->
  if beginBusy(busyAnimation, animation, action, state)
    consumeAction(enqueue(animation, action.func, {action, state}))
  else if busyEnd(busyAnimation, action)
    {action, state: dequeue(animation, state)}
  else
    {action, state}



initialize = R.assoc(R.__, {busy:0, next:null, queue:[]}, R.__)
initializeAnimationState = ({action, state}) ->
  if action.animation of state
    return {action, state}
  else
    return R.evolve({state:initialize(action.animation)}, {action, state})

log = (value) ->
  console.log(value)
  return value

handleAction = R.compose(
  R.identity
  initializeAnimationState
)

###
state = {
  animation: {
    busy: 0
    next: func or null
    queue: [] or [func, ...]
  }
}

action = {
  type: 'begin' or 'end'
  animation: animation
  func: func
}

all functions here have a done callback as the first and only arguement
###

flyd.scan ((state, action) ->
  console.log action, state
  {state, action} = handleAction({state, action})

  # the action can be consumed by handleAction
  # if its not consumed, then we can run the animation
  # or set busy to false
  if action.type is 'begin'
    {func, animation} = action
    startAnimation(animation, func)
    state[animation].busy += 1
    # state = R.assocPath([animation, 'busy'], true, state)
  else if action.type is 'end'
    {animation} = action
    state[animation].busy -= 1
    state = dequeue(animation, state)
    # state = R.assocPath([animation, 'busy'], false, state)

  return state
), {}, animation$


enqueueAnimation = (animation, func) ->
  animation$({type:'begin', animation, func})

_.extend(this, {enqueueAnimation})