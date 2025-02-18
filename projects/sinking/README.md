# Sinking

A low-code backend designed to dump out it's guts.

Featues I want to have:

- All records are CRDTs
- APIs for downloading and uploading data in bulk
- Realtime API over websockets

## Models

Project -< User
Project -< ProjectUser
Project -< Table
Table -< Record

## Record states:

Records are a CRDT.

Content conflicts are resolved on a field by field basis.

States:
- Nonexistant
- Readable
- Writable
- Deleted

### Syncing

The client sends a copy of all of it's data, including the traces of deleted
records. The server updates it's dataset based off of the data

```ts
type Record = {
  id: string,
  createdAt: number,
  values: {
    <value>: {
      current: <type>,
      updatedAt: number
    }
  }
} | {
  id: string,
  deletedAt: number
}
```
