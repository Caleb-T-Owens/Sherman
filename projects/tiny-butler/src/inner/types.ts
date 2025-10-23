export type Repository = {
    findCommit(id: CommitId): Promise<Commit>
    findTree(id: TreeId): Promise<Tree>
    findBlob(id: BlobId): Promise<Blob>
    findObj(id: ObjId): Promise<Obj>
}

export type CommitId = {
    type: 'commit',
    value: string
}

export type TreeId = {
    type: 'tree',
    value: string
}

export type BlobId = {
    type: 'blob',
    value: string
}

export type ObjId = CommitId | TreeId | BlobId

export type Commit = {
    type: 'commit',
    id: CommitId,
    parents: CommitId[],
    tree: TreeId,
    author: Signature,
    committer: Signature,
    extraHeaders: [string, string][],
    message: string
}

export type Tree = {
    type: 'tree',
    id: TreeId,
    entries: TreeEntry[]
}

export type TreeEntry = {
    permission: number,
    id: ObjId,
    name: string
}

export type Blob = {
    type: 'blob',
    id: BlobId,
    content: string
}

export type Obj = Commit | Tree | Blob

type Signature = {
    name: string,
    email: string,
    timestamp: number
}