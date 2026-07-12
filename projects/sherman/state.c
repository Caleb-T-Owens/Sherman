/* state.c — what has been applied, and how to take it back.
 *
 * Every successfully applied node gets a directory under the state root
 * (default ~/.local/state/sherman, override with $SHERMAN_STATE_DIR):
 *
 *   <state>/<node-name>/hash   input hash at apply time
 *   <state>/<node-name>/outs   "<sha256> <mode> <path>" per produced file
 *   <state>/<node-name>/undo   snapshot of the uninstall block, if any
 *   <state>/<node-name>/log    output of the last run
 *
 * The undo script is snapshotted here rather than read from the repo, so
 * a configset can be un-applied even after its directory is deleted from
 * the repo entirely.
 *
 * GC: a state entry whose name is not in the currently loaded graph was
 * removed from the env.  Undoing it means running the undo snapshot, then
 * deleting each recorded out whose content still matches its recorded
 * hash — a mismatch means the user edited the file by hand, and we warn
 * and leave it alone rather than destroy their work. */
#include "sherman.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

const char *state_root(void)
{
    static const char *root;
    if (!root) {
        const char *override = getenv("SHERMAN_STATE_DIR");
        root = override ? xstrdup(override)
                        : xprintf("%s/.local/state/sherman", getenv("HOME"));
    }
    return root;
}

char *state_read_hash(const char *name)
{
    char *text = read_file(xprintf("%s/%s/hash", state_root(), name), NULL);
    return text ? trim(text) : NULL;
}

/* Content hash of one file, streamed so big binaries never sit in memory. */
static bool hash_file_hex(const char *path, char out[65])
{
    struct stat st;
    if (lstat(path, &st) != 0)
        return false;

    Sha256 ctx;
    sha256_init(&ctx);
    if (S_ISLNK(st.st_mode)) {
        size_t len;
        char *target = read_link(path, &len);
        if (!target)
            return false;
        sha256_update(&ctx, target, len);
        sha256_hex(&ctx, out);
        return true;
    }
    if (!S_ISREG(st.st_mode)) {
        errno = EISDIR;
        return false;
    }

    int fd = open(path, O_RDONLY);
    if (fd < 0)
        return false;

    char buf[64 * 1024];
    ssize_t got;
    while ((got = read(fd, buf, sizeof buf)) > 0)
        sha256_update(&ctx, buf, (size_t)got);
    if (got < 0) {
        int read_errno = errno;
        close(fd);
        errno = read_errno;
        return false;
    }
    close(fd);
    sha256_hex(&ctx, out);
    return true;
}

/* Write via tmp + rename so a crash can never leave a half-written state
 * file behind. */
static void write_file_atomic(const char *path, const char *text)
{
    char *tmp = xprintf("%s.tmp", path);
    write_file(tmp, text);
    if (rename(tmp, path) != 0)
        die("rename %s: %s", path, strerror(errno));
}

/* ═══ recording an applied node ═════════════════════════════════════════ */

/* The manifest of files this node put on the machine: every change DST
 * plus every declared out, one "<sha256> <mode> <path>" line per file.
 * Directories expand to the files they now contain — right after a dir
 * copy, those are exactly the files we created.  Hashes make removal safe;
 * modes let apply reconcile chmod-only drift. */
static char *build_outs_manifest(const Node *n, bool report,
                                 bool *complete_out)
{
    bool complete = true;
    StrList produced = {0};
    for (size_t i = 0; i < n->nchanges; i++)
        strlist_push(&produced, xstrdup(n->changes[i].dst));
    for (size_t i = 0; i < n->outs.len; i++)
        strlist_push(&produced, n->outs.items[i]);

    StrBuf manifest = {0};
    for (size_t i = 0; i < produced.len; i++) {
        struct stat st;
        if (lstat(produced.items[i], &st) != 0) {
            complete = false;
            if (report)
                printf("       note: declared out missing after run: %s\n",
                       produced.items[i]);
            continue;
        }

        StrList files = {0};
        const char *err = collect_files(produced.items[i], &files);
        if (err) {
            complete = false;
            if (report)
                printf("       note: cannot record outs under %s (%s)\n",
                       produced.items[i], err);
            continue;
        }

        for (size_t j = 0; j < files.len; j++) {
            if (lstat(files.items[j], &st) != 0) {
                complete = false;
                continue;
            }
            if (S_ISDIR(st.st_mode)) {
                sb_puts(&manifest, "dir ");
                sb_puts(&manifest, xprintf("%04o", st.st_mode & 07777));
                sb_putc(&manifest, ' ');
                sb_puts(&manifest, files.items[j]);
                sb_putc(&manifest, '\n');
                continue;
            }

            char hex[65];
            if (!hash_file_hex(files.items[j], hex)) {
                complete = false;
                continue;
            }
            sb_puts(&manifest, hex);
            sb_putc(&manifest, ' ');
            sb_puts(&manifest, xprintf("%04o", st.st_mode & 07777));
            sb_putc(&manifest, ' ');
            sb_puts(&manifest, files.items[j]);
            sb_putc(&manifest, '\n');
        }
    }
    if (complete_out)
        *complete_out = complete;
    return sb_str(&manifest);
}

bool state_outputs_match(const Node *n)
{
    char *recorded = read_file(
        xprintf("%s/%s/outs", state_root(), n->name), NULL);
    if (!recorded)
        return false;

    bool complete;
    char *current = build_outs_manifest(n, false, &complete);
    return complete && strcmp(recorded, current) == 0;
}

void state_write(Node *n)
{
    char *dir = xprintf("%s/%s", state_root(), n->name);
    mkdirs(dir);

    /* outs and undo first, hash LAST: the hash file is the commit record.
     * A crash in between leaves the node looking unapplied — it merely
     * re-runs next time — instead of marked applied with a stale undo. */
    write_file_atomic(xprintf("%s/outs", dir),
                      build_outs_manifest(n, true, NULL));

    char *undopath = xprintf("%s/undo", dir);
    if (n->uninstall)
        write_file_atomic(undopath, xprintf("%s\n", n->uninstall));
    else
        unlink(undopath);

    write_file_atomic(xprintf("%s/hash", dir), xprintf("%s\n", n->hash));
}

/* ═══ undoing a removed node ════════════════════════════════════════════ */

/* Run a snapshotted undo script: bash -e, cwd = the state entry dir (the
 * configset's repo dir may no longer exist).  Returns the exit status. */
static int run_undo_script(const char *cwd, const char *script_path)
{
    fflush(stdout);
    pid_t pid = fork();
    if (pid < 0)
        die("fork: %s", strerror(errno));

    if (pid == 0) {
        if (chdir(cwd) != 0) { perror("chdir"); _exit(127); }
        execl("/bin/bash", "bash", "-e", script_path, (char *)NULL);
        perror("exec bash");
        _exit(127);
    }

    int status;
    while (waitpid(pid, &status, 0) < 0)
        if (errno != EINTR)
            die("waitpid: %s", strerror(errno));
    return status;
}

/* Does root (a change DST or declared out of a live node) cover path —
 * either exactly, or as a directory prefix? */
static bool path_covered_by(const char *path, const char *root)
{
    size_t n = strlen(root);
    return strncmp(path, root, n) == 0 &&
           (path[n] == '\0' || path[n] == '/');
}

/* Is this path also produced by a node in the CURRENT graph?  This is the
 * rename guard: when a configset is renamed but keeps its destinations,
 * the new name applies first and GC of the old name must not delete the
 * files the new node just installed. */
static const Node *live_owner_of(const char *path)
{
    for (size_t i = 0; i < all_nodes.len; i++) {
        const Node *node = all_nodes.items[i];
        for (size_t j = 0; j < node->nchanges; j++)
            if (path_covered_by(path, node->changes[j].dst))
                return node;
        for (size_t j = 0; j < node->outs.len; j++)
            if (path_covered_by(path, node->outs.items[j]))
                return node;
    }
    return NULL;
}

/* Delete the files a node's manifest recorded — but only the ones whose
 * content still matches the hash we wrote at apply time, and which no
 * currently-live node claims. */
static bool remove_recorded_outs(const char *name, const char *entry_dir)
{
    bool ok = true;
    char *cursor = read_file(xprintf("%s/outs", entry_dir), NULL);
    char *line;
    while ((line = next_line(&cursor)) != NULL) {
        if (starts_with(line, "dir "))
            continue;                   /* deliberate: leave empty dirs */
        if (strlen(line) < 66)
            continue;                   /* not a "<64-hex> <path>" line */
        line[64] = '\0';
        const char *recorded = line;
        const char *path = line + 65;
        if (strlen(path) >= 6 && path[4] == ' ' &&
            strspn(path, "01234567") >= 4)
            path += 5;                  /* current "<mode> <path>" format */

        const Node *owner = live_owner_of(path);
        if (owner) {
            printf("[ gc ] %s: keeping %s (owned by %s now)\n",
                   name, path, owner->name);
            continue;
        }

        struct stat st;
        if (lstat(path, &st) != 0) {
            if (errno == ENOENT)
                continue;               /* already gone */
            printf("[ gc ] %s: cannot inspect %s: %s\n",
                   name, path, strerror(errno));
            ok = false;
            continue;
        }

        char current[65];
        if (!hash_file_hex(path, current)) {
            printf("[ gc ] %s: cannot verify %s: %s\n",
                   name, path, strerror(errno));
            ok = false;
            continue;
        }

        if (strcmp(current, recorded) != 0) {
            printf("[ gc ] %s: %s was modified by hand — leaving it\n",
                   name, path);
            continue;
        }

        printf("[ gc ] %s: removing %s\n", name, path);
        if (unlink(path) != 0 && errno != ENOENT) {
            printf("[ gc ] %s: cannot remove %s: %s\n",
                   name, path, strerror(errno));
            ok = false;
        }
    }
    return ok;
}

static bool undo_entry(const char *name)
{
    char *entry_dir = xprintf("%s/%s", state_root(), name);

    /* The undo script runs first: it may need the outs still in place. */
    char *undopath = xprintf("%s/undo", entry_dir);
    struct stat st;
    if (stat(undopath, &st) == 0) {
        printf("[ gc ] %s: running uninstall\n", name);
        if (run_undo_script(entry_dir, undopath) != 0) {
            printf("[ gc ] %s: uninstall failed (kept state; will retry "
                   "next apply)\n", name);
            return false;
        }
        unlink(undopath);       /* do not repeat a successful uninstall */
    }

    if (!remove_recorded_outs(name, entry_dir)) {
        printf("[ gc ] %s: removal failed (kept state; will retry next apply)\n",
               name);
        return false;
    }

    /* Remove only this entry's own files: configset names can nest
     * (foo and foo/bar), so <state>/foo may contain a LIVE entry at
     * <state>/foo/bar that a recursive delete would destroy. */
    unlink(xprintf("%s/hash", entry_dir));
    unlink(xprintf("%s/outs", entry_dir));
    unlink(xprintf("%s/undo", entry_dir));
    unlink(xprintf("%s/log", entry_dir));
    rmdir(entry_dir);       /* fails harmlessly when nested entries remain */
    return true;
}

/* ═══ finding removed entries ═══════════════════════════════════════════ */

/* Depth-first over the state root; a directory containing `hash` is an
 * entry.  Entries are collected before any undoing happens, because
 * undo_entry mutates the tree we would still be walking.  The walk keeps
 * descending below an entry: nested configset names (foo and foo/bar)
 * nest their state dirs too. */
static void find_entries(const char *dir, const char *rel, StrList *found)
{
    struct stat st;
    if (rel[0] != '\0' && stat(xprintf("%s/hash", dir), &st) == 0)
        strlist_push(found, xstrdup(rel));

    DIR *d = opendir(dir);
    if (!d)
        return;

    struct dirent *e;
    while ((e = readdir(d)) != NULL) {
        if (e->d_name[0] == '.')
            continue;
        char *sub = xprintf("%s/%s", dir, e->d_name);
        if (stat(sub, &st) == 0 && S_ISDIR(st.st_mode))
            find_entries(sub,
                         rel[0] ? xprintf("%s/%s", rel, e->d_name)
                                : xstrdup(e->d_name),
                         found);
    }
    closedir(d);
}

/* tmp-log files survive a crashed or ^C'd run; nothing else can own them
 * in the single-user model, so sweep them on every start. */
void sweep_stale_logs(void)
{
    DIR *d = opendir(state_root());
    if (!d)
        return;

    struct dirent *e;
    while ((e = readdir(d)) != NULL)
        if (starts_with(e->d_name, "tmp-log-"))
            unlink(xprintf("%s/%s", state_root(), e->d_name));
    closedir(d);
}

int gc_removed(bool dry_run)
{
    int failures = 0;
    StrList entries = {0};
    find_entries(state_root(), "", &entries);

    for (size_t i = 0; i < entries.len; i++) {
        const char *name = entries.items[i];
        if (find_node(name))
            continue;                   /* still part of the env */

        if (dry_run)
            printf("[ gc ] would undo %s (no longer in this env)\n", name);
        else if (!undo_entry(name))
            failures++;
    }
    return failures;
}
