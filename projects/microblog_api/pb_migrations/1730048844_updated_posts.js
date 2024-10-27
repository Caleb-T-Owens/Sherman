/// <reference path="../pb_data/types.d.ts" />
migrate((db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("w2quyhbpjqkc9cr")

  collection.createRule = "@request.auth.id = @collection.posts.microblog.userId"
  collection.updateRule = "@request.auth.id = @collection.posts.microblog.userId"
  collection.deleteRule = "@request.auth.id = @collection.posts.microblog.userId"
  collection.indexes = [
    "CREATE INDEX `idx_nFYKm2K` ON `posts` (`microblog`)"
  ]

  // update
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "l5pxsvsz",
    "name": "microblog",
    "type": "relation",
    "required": true,
    "presentable": false,
    "unique": false,
    "options": {
      "collectionId": "dj22esvbu1degx0",
      "cascadeDelete": true,
      "minSelect": null,
      "maxSelect": 1,
      "displayFields": null
    }
  }))

  return dao.saveCollection(collection)
}, (db) => {
  const dao = new Dao(db)
  const collection = dao.findCollectionByNameOrId("w2quyhbpjqkc9cr")

  collection.createRule = "@request.auth.id = @collection.posts.microblogId.userId"
  collection.updateRule = "@request.auth.id = @collection.posts.microblogId.userId"
  collection.deleteRule = "@request.auth.id = @collection.posts.microblogId.userId"
  collection.indexes = [
    "CREATE INDEX `idx_nFYKm2K` ON `posts` (`microblogId`)"
  ]

  // update
  collection.schema.addField(new SchemaField({
    "system": false,
    "id": "l5pxsvsz",
    "name": "microblogId",
    "type": "relation",
    "required": true,
    "presentable": false,
    "unique": false,
    "options": {
      "collectionId": "dj22esvbu1degx0",
      "cascadeDelete": true,
      "minSelect": null,
      "maxSelect": 1,
      "displayFields": null
    }
  }))

  return dao.saveCollection(collection)
})
