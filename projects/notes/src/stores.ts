import { LazyStore } from "@tauri-apps/plugin-store";
import { BehaviorSubject, map, Observable } from "rxjs";
import { ReadonlyBehaviorSubject } from "./rxjs";

const notesStore = new LazyStore("notes.json");
const noteKindsStore = new LazyStore("note_kinds.json");
const attributeDefinitionsStore = new LazyStore("attribute_definitions.json");

function genId() {
    return crypto.randomUUID();
}

export type Note = {
    id: string,
    path: string,
    content: string,
    embedding?: number[],
    attributes: Attribute[]
    noteKindId: string,
}

export type NoteKind = {
    id: string,
    name: string
}

export type Attribute = {
    attributeId: string,
    value: string
}

export type AttributeDefinition = {
    id: string,
    name: string,
    type: 'string' | 'boolean'
}

type Idable = { id: string }

class Model<T extends Idable> {
    private allSubject = new BehaviorSubject<Map<string, T>>(new Map());

    constructor(private readonly store: LazyStore) {
        this.refetchAll()
    }

    private async refetchAll() {
        const all = new Map(await this.store.entries<T>())
        this.allSubject.next(all);
    }

    all(): ReadonlyBehaviorSubject<Map<string, T>> {
        return this.allSubject
    }

    get(id: string): Observable<T | undefined> {
        return this.allSubject.pipe(map((value => value.get(id))))
    }

    async set(id: string, value: T) {
        await this.store.set(id, value)
        this.allSubject.next(this.allSubject.getValue().set(id, value))
    }

    async create(creation: Omit<T, 'id'>) {
        const id = genId()
        const value = { ...creation, id } as T
        await this.store.set(id, value)
        this.allSubject.next(this.allSubject.getValue().set(id, value))
        return id
    }
}

export const notesModel = new Model<Note>(notesStore);
export const noteKindsModel = new Model<NoteKind>(noteKindsStore);
export const attributeDefinitionsModel = new Model<AttributeDefinition>(attributeDefinitionsStore);

window.notesModel = notesModel
window.notesStore = notesStore