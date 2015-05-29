Meteor.methods
  usernameExists: (username) ->
    Meteor.users.findOne({username}) isnt undefined
  setItemChecked: (itemId, checked) ->
    item = Items.findOne(itemId)
    listId = item.listId
    if Lists.findOne({userId:@userId, _id:listId})
      Items.update(itemId, {$set:{checked}})
      Lists.update(listId, {$set:{unchecked:Items.find({listId, checked:false}).count()}})

  newItem: (listId, title) ->
    if Lists.findOne({userId:@userId, _id:listId})
      Items.insert({title, listId, checked:false})
      Lists.update(listId, {$set:{unchecked:Items.find({listId, checked:false}).count()}})

  setListTitle: (listId, title) ->
    if Lists.findOne({userId:@userId, _id:listId})
      Lists.update(listId, {$set:{title}})