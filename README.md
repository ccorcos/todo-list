# Todo List

The goal of this project is to use Meteor, React, and VelocityJS to create an entirely animated, performant, cross-platform todo list app.

Every React view ought to be pure. There is a global `app.state` which is used to render a top level component. All functionality is delegated to the `app.controller`. Animations are asynchronous functions where the only arguement is a callback when the animation is finished. A `flyd.stream` (an observable streams library) arbitrates all animations. You can run an animation using `enqueueAnimation(name, func)` where name describes the animation in some why. Then using `dropOn`, `queueLatestOn`, and `queueAllOn`, you can describe the relationships of how these animations (actions) can block or queue each other. 

# To Do

edit list title
new item
delete item

-newList
-newItem
-deleteList
-deleteItem
-editList
-editItem
-use flyd for swipe actions?

-list hero animation - animate textAlign center? animate fontSize?
-animation queuing