import { useSubject } from '../rxjs';
import { notesModel } from '../stores';

export function Root() {
  return (
    <>
      <div className="flex h-screen w-screen">
        <div className="flex-2">
          <NotesList />
        </div>
        <div className="flex-8">
          <h1>Main</h1>
          <button onClick={createRandomNote}>Create random note</button>
        </div>
        <div className="flex-2">Meta</div>
      </div>
    </>
  );
}

function createRandomNote() {
  notesModel.create({
    path: `foo/bar/${crypto.randomUUID()}`,
    content: "I'm a note!",
    noteKindId: 'foobar',
    attributes: []
  });
}

function NotesList() {
  const notes = useSubject(notesModel.all());

  return (
    <ul>
      {[...notes.values()].map((note) => (
        <li key={note.id}>{note.path}</li>
      ))}
    </ul>
  );
}
