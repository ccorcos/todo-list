
RegisterRefMixin = (name) ->
  componentWillMount: ->
    app.refs[name] = this

lookupRef = (string) ->
  component = R.pick(['refs'], app)
  path = R.split('.', string)
  while path.length > 0 and component
    component = component.refs[R.head(path)]
    path = R.tail(path)
  return component
  
getDOMNode = R.compose(R.call, R.prop('getDOMNode'))
$ref = R.compose($, getDOMNode, lookupRef)
lookupDOMNodes = R.compose(R.map(getDOMNode), R.filter(R.complement(R.isNil)), R.map(lookupRef))
$refs = R.compose($, lookupDOMNodes)

# animate refs using $.velocity
animate = R.curry (refNames, transition, options, complete) ->
  options = R.merge({display:null, complete}, options)
  $refs(refNames).velocity(transition, options)


nthCallOf = (nth, func) ->
  n = 0
  () ->
    n += 1
    if n is nth then func()

callBoth = (a,b) ->
  () -> R.map(R.call, [a,b])

hideRefs = (refs) ->
  $refs(refs).css('opacity', 0)

unhideRefs = (refs) ->
  $refs(refs).css('opacity', 1)

animateCappedStagger = R.curry (n, animation, ms, refs, done) ->
  hideRefs(R.drop(n, refs))
  complete = nthCallOf(2, done)
  animate(R.take(n, refs), animation, {stagger:ms}, complete)
  animate(R.drop(n, refs), animation, {delay: ms*(n-1)}, complete)
    
# expose global
_.extend(this, {
  RegisterRefMixin
  lookupRef
  animate
  nthCallOf
  callBoth
  hideRefs
  unhideRefs
  animateCappedStagger
  $ref
  $refs
})