/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("dj22esvbu1degx0")

  collection.updateRule = "@request.auth.id = @collection.microblogs.userId"
  collection.deleteRule = "@request.auth.id = @collection.microblogs.userId"

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("dj22esvbu1degx0")

  collection.updateRule = null
  collection.deleteRule = null

  return dao.saveCollection(collection)
})
