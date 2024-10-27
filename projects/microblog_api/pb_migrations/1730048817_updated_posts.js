/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("w2quyhbpjqkc9cr")

  collection.createRule = "@request.auth.id = @collection.posts.microblogId.userId"
  collection.updateRule = "@request.auth.id = @collection.posts.microblogId.userId"
  collection.deleteRule = "@request.auth.id = @collection.posts.microblogId.userId"

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("w2quyhbpjqkc9cr")

  collection.createRule = null
  collection.updateRule = null
  collection.deleteRule = null

  return dao.saveCollection(collection)
})
