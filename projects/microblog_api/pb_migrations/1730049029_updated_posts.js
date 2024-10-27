/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("w2quyhbpjqkc9cr")

  collection.createRule = "@request.auth.id = microblog.user.id"
  collection.updateRule = "@request.auth.id = microblog.user.id"
  collection.deleteRule = "@request.auth.id = microblog.user.id"

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("w2quyhbpjqkc9cr")

  collection.createRule = "@request.auth.id = @collection.posts.microblog.user.id"
  collection.updateRule = "@request.auth.id = @collection.posts.microblog.user.id"
  collection.deleteRule = "@request.auth.id = @collection.posts.microblog.user.id"

  return dao.saveCollection(collection)
})
