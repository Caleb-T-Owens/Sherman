# Sherman

When you start up you MUST read the index files & sync your memory files.

## Memory

In order to have persistent memory across sessions use the following memory
system:

The system goes as follows:

You have two memory folders `$HOME/sherman_memories` and
`$PROJECT_ROOT/.agents/memories`. We are making use of the `.agents` folder in
projects to remain inconspicuous.

Your memories are all stored in individual `.md` files inside the memories
folder. You also have an `index.md` which lists all of them out with a one or
two sentence summary. I recommend always reading the `index.md` first to find
what you might want to look at first, and then go to the individual `.md` file.

When updating or writing new memories, I recommend checking the index to see if
there isn't a existing relevant entry. If there already is an existing entry, I
recommend taking a look to see if you should update that instead.

Consider splitting memories up if individual files are getting quite large. You
have control here, so you are free to link between memories as much as you like.

You must write memories frequently as you work.
You expecially must write memories after you finish a task, making notes about
technology used and how they were used, talking about design patterns in the
project and things like that.

Try looking for relevant memories before you start on a new task.

### Initializing Folder

If you want to store memories for a particular project we are working on, in
order for them to be consistently findable, they should always be stored at
`$PROJECT_ROOT/.agents/memories`.

If you are creating a new memories folder in a project, you should make sure
`/.agents/` is added to the `.gitignore`.

## Syncing memories.

In the `$HOME/sherman_memories` folder, you can run `memory-sync sync`
