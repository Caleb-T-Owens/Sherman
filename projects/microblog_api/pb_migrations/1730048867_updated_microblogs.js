/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("dj22esvbu1degx0")

  collection.createRule = ""
  collection.updateRule = "@request.auth.id = @collection.microblogs.user.id"
  collection.deleteRule = "@request.auth.id = @collection.microblogs.user.id"
  collection.indexes = [
    "CREATE INDEX `idx_5WAUFdp` ON `microblogs` (`user`)",
    "CREATE UNIQUE INDEX `idx_oRdaJD8` ON `microblogs` (`slug`)"
  ]

  // update
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "cy4zxd16",
    "name": "user",
    "type": "relation",
    "required": true,
    "presentable": false,
    "unique": false,
    "options": {
      "collectionId": "_pb_users_auth_",
      "cascadeDelete": true,
      "minSelect": null,
      "maxSelect": 1,
      "displayFields": null
    }
  }))

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("dj22esvbu1degx0")

  collection.createRule = null
  collection.updateRule = "@request.auth.id = @collection.microblogs.userId"
  collection.deleteRule = "@request.auth.id = @collection.microblogs.userId"
  collection.indexes = [
    "CREATE INDEX `idx_5WAUFdp` ON `microblogs` (`userId`)",
    "CREATE UNIQUE INDEX `idx_oRdaJD8` ON `microblogs` (`slug`)"
  ]

  // update
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "cy4zxd16",
    "name": "userId",
    "type": "relation",
    "required": true,
    "presentable": false,
    "unique": false,
    "options": {
      "collectionId": "_pb_users_auth_",
      "cascadeDelete": true,
      "minSelect": null,
      "maxSelect": 1,
      "displayFields": null
    }
  }))

  return dao.saveCollection(collection)
})
