/* verbs.c — the `change` verbs and the filesystem helpers they need.
 *
 * v1 has one verb: copy.  `copy SRC DST` copies a file or a whole
 * directory.  Directories are replaced wholesale — DST is removed first —
 * matching what the old install scripts did with `rm -r && cp -R`.
 *
 * apply_changes runs inside the forked child, so its errors print into
 * the captured output stream and kill only that child. */
#include "sherman.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

/* Refuse to delete anything that isn't a plausible install target.  These
 * paths only ever come from expanded `change` lines, but a $HOME-typo
 * class of mistake should hit a wall, not the filesystem. */
static void guard_deletable(const char *path)
{
    const char *home = getenv("HOME");
    size_t len = strlen(path);

    if (path[0] != '/' || len == 1 || path[len - 1] == '/' ||
        strstr(path, "//") != NULL)
        die("refusing to remove '%s'", path);
    if (home && strcmp(path, home) == 0)
        die("refusing to remove $HOME itself ('%s')", path);

    for (const char *part = path + 1; part; ) {
        const char *slash = strchr(part, '/');
        size_t part_len = slash ? (size_t)(slash - part) : strlen(part);
        if ((part_len == 1 && part[0] == '.') ||
            (part_len == 2 && part[0] == '.' && part[1] == '.'))
            die("refusing to remove non-canonical path '%s'", path);
        part = slash ? slash + 1 : NULL;
    }
}

int remove_tree(const char *path)
{
    struct stat st;
    if (lstat(path, &st) != 0)
        return errno == ENOENT ? 0 : -1;    /* already absent is success */

    if (!S_ISDIR(st.st_mode))
        return unlink(path);

    DIR *d = opendir(path);
    if (!d)
        return -1;

    int rc = 0;
    struct dirent *e;
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0)
            continue;
        if (remove_tree(xprintf("%s/%s", path, e->d_name)) != 0)
            rc = -1;
    }
    closedir(d);

    if (rc == 0)
        rc = rmdir(path);
    return rc;
}

/* ═══ the copy verb ═════════════════════════════════════════════════════ */

static void copy_file(const char *src, const char *dst)
{
    struct stat st;
    if (lstat(src, &st) != 0)
        die("copy: cannot stat %s: %s", src, strerror(errno));

    /* Make sure the destination's parent directory exists. */
    char *parent = xstrdup(dst);
    char *slash = strrchr(parent, '/');
    if (slash && slash != parent) {
        *slash = '\0';
        mkdirs(parent);
    }

    if (S_ISLNK(st.st_mode)) {
        char *target = read_link(src, NULL);
        if (!target)
            die("copy: cannot readlink %s: %s", src, strerror(errno));
        if (unlink(dst) != 0 && errno != ENOENT)
            die("copy: cannot replace %s: %s", dst, strerror(errno));
        if (symlink(target, dst) != 0)
            die("copy: cannot symlink %s: %s", dst, strerror(errno));
        return;
    }

    int in = open(src, O_RDONLY);
    if (in < 0)
        die("copy: cannot open %s: %s", src, strerror(errno));

    /* Recreate rather than overwrite, carrying the source's mode so
     * executable scripts stay executable. */
    unlink(dst);
    int out = open(dst, O_WRONLY | O_CREAT | O_TRUNC, st.st_mode & 0777);
    if (out < 0)
        die("copy: cannot create %s: %s", dst, strerror(errno));

    char buf[64 * 1024];
    ssize_t n;
    while ((n = read(in, buf, sizeof buf)) > 0) {
        ssize_t off = 0;
        while (off < n) {
            ssize_t w = write(out, buf + off, (size_t)(n - off));
            if (w < 0)
                die("copy: write %s: %s", dst, strerror(errno));
            off += w;
        }
    }
    if (n < 0)
        die("copy: read %s: %s", src, strerror(errno));

    if (close(out) != 0)
        die("copy: close %s: %s", dst, strerror(errno));
    close(in);
}

static void copy_dir(const char *src, const char *dst)
{
    struct stat src_st;
    if (stat(src, &src_st) != 0)
        die("copy: cannot stat dir %s: %s", src, strerror(errno));
    mkdirs(dst);

    DIR *d = opendir(src);
    if (!d)
        die("copy: cannot open dir %s: %s", src, strerror(errno));

    struct dirent *e;
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0)
            continue;

        char *from = xprintf("%s/%s", src, e->d_name);
        char *to = xprintf("%s/%s", dst, e->d_name);

        struct stat st;
        if (lstat(from, &st) != 0)
            die("copy: cannot stat %s: %s", from, strerror(errno));

        if (S_ISDIR(st.st_mode))
            copy_dir(from, to);
        else
            copy_file(from, to);
    }
    closedir(d);
    if (chmod(dst, src_st.st_mode & 0777) != 0)
        die("copy: cannot chmod dir %s: %s", dst, strerror(errno));
}

void apply_changes(const Node *n)
{
    for (size_t i = 0; i < n->nchanges; i++) {
        const Change *change = &n->changes[i];

        struct stat st;
        if (lstat(change->src, &st) != 0)
            die("change: source missing: %s", change->src);

        guard_deletable(change->dst);
        printf("copy %s -> %s\n", change->src, change->dst);

        if (S_ISDIR(st.st_mode)) {
            /* Directory copies replace the destination wholesale. */
            if (remove_tree(change->dst) != 0)
                die("change: cannot clear %s: %s", change->dst,
                    strerror(errno));
            copy_dir(change->src, change->dst);
        } else {
            copy_file(change->src, change->dst);
        }
    }
}

/* ═══ shared filesystem walking ═════════════════════════════════════════
 *
 * Used by run.c to hash inputs and by state.c to build outs manifests. */

static int cmp_str(const void *a, const void *b)
{
    return strcmp(*(char *const *)a, *(char *const *)b);
}

static bool ignored_entry(const char *name)
{
    return strcmp(name, ".git") == 0 ||
           strcmp(name, ".DS_Store") == 0 ||
           strcmp(name, "make-lock") == 0;
}

/* Append every entry under path, including directories, to out.
 * Directory entries are visited in sorted order so the result — and
 * therefore any hash built from it — is deterministic.  Symlinks are
 * recorded but never followed (a dangling link in some node_modules must
 * not break the walk).
 *
 * Returns NULL on success or an error message: callers decide whether a
 * bad path fails one node or is merely noted — it must never kill the
 * whole run, which has parallel children in flight. */
const char *collect_files(const char *path, StrList *out)
{
    struct stat st;
    if (lstat(path, &st) != 0)
        return xprintf("cannot stat %s: %s", path, strerror(errno));

    strlist_push(out, xstrdup(path));
    if (!S_ISDIR(st.st_mode))
        return NULL;

    DIR *d = opendir(path);
    if (!d)
        return xprintf("cannot open dir %s: %s", path, strerror(errno));

    StrList names = {0};
    struct dirent *e;
    while ((e = readdir(d)) != NULL) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0)
            continue;
        if (ignored_entry(e->d_name))
            continue;
        strlist_push(&names, xstrdup(e->d_name));
    }
    closedir(d);

    qsort(names.items, names.len, sizeof *names.items, cmp_str);

    for (size_t i = 0; i < names.len; i++) {
        const char *err =
            collect_files(xprintf("%s/%s", path, names.items[i]), out);
        if (err)
            return err;
    }
    return NULL;
}
