Meteor.startup ->
  if Meteor.users.find().count() is 0
    userId = Accounts.createUser
      username: "chet"
      password: "1234"
      email: "ccorcos@gmail.com"

    listId = Lists.insert({userId, title:'hackathon', unchecked:1})
    Items.insert({listId, title:'find a partner', checked:true})
    Items.insert({listId, title:'think up a project', checked:false})

    listId = Lists.insert({userId, title:'todo app', unchecked:2})
    Items.insert({listId, title:'writeup the readme', checked:false})
    Items.insert({listId, title:'post on crater.io', checked:false})

    