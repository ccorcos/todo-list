_ = lodash

# Initialize React to respond to touch events
React.initializeTouchEvents(true)
# to get :active pseudoselector working
document.addEventListener("touchstart", (()->), false)
# also need cursor:pointer to work on mobile
React.createClassFactory = R.compose(React.createFactory, React.createClass)


app = {}
app.refs = {}
app.state = {}
app.views = {}
app.controller = {}
app.animations = {}
app.subscriptions = {}

_.extend(this, {app, _})