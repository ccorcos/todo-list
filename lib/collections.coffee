@Lists = new Mongo.Collection('lists')
@Items = new Mongo.Collection('items')

Meteor.methods
  usernameExists: (username) ->
    Meteor.users.findOne({username}) isnt undefined