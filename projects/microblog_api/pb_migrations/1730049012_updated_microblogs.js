/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("dj22esvbu1degx0")

  collection.updateRule = "@request.auth.id = user.id"
  collection.deleteRule = "@request.auth.id = user.id"

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("dj22esvbu1degx0")

  collection.updateRule = "@request.auth.id = @collection.microblogs.user.id"
  collection.deleteRule = "@request.auth.id = @collection.microblogs.user.id"

  return dao.saveCollection(collection)
})
