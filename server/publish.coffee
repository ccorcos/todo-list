Meteor.publish 'lists', (limit) ->
  if @userId
    Lists.find({userId:@userId}, {limit:limit, sort: { title:1 }})

Meteor.publish 'list', (listId) ->
  if @userId and Lists.findOne(listId).userId is @userId
    [Items.find({listId}), Lists.find(listId)]
