# Todo List

The goal of this project is to use Meteor, React, and VelocityJS to create an entirely animated, performant, cross-platform todo list app.

Every React view ought to be pure. There is a global `app.state` which is used to render a top level component. All functionality is delegated to the `app.controller`. Animations are asynchronous functions where the only arguement is a callback when the animation is finished. A `flyd.stream` (an observable streams library) arbitrates all animations. You can run an animation using `enqueueAnimation(name, func)` where name describes the animation in some why. Then using `dropOn`, `queueLatestOn`, and `queueAllOn`, you can describe the relationships of how these animations (actions) can block or queue each other. 

# To Do

delete item -- swipe with flyd?
-newList
-deleteList
-deleteItem
-list hero animation - animate textAlign center? animate fontSize?
-animation queuing
-hero animation from lists to list

refactor:
- animate only if there was a change

# Separation of Concerns

subscription:
- subscribe to something
- watch some cursors and animate changes
- update the subscription when necessary

view:
- pure render with React
- call actions in the controller or the subscription

controller:
- handle all actions that have to do with animation, changing UI, or changing state
- everything except data from a subscription