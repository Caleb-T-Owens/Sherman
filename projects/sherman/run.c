/* run.c — input hashing and the parallel executor.
 *
 * The scheduler in one paragraph: every node starts WAITING with a count
 * of unfinished dependencies; nodes whose count is zero go into the ready
 * list.  We keep up to maxjobs children alive.  Starting a ready node
 * means hashing its inputs first — if the hash matches the state store it
 * finishes as UP_TO_DATE without a child.  When a node finishes, it
 * decrements each dependent's count (and, on failure, poisons them so
 * they finish as SKIPPED instead of running).  The parent process stays
 * single-threaded; all parallelism is child processes.
 *
 * Output: each child's stdout+stderr feed a pipe.  The parent polls every
 * live pipe and streams complete lines as "<node> | <line>" (docker-compose
 * style, colored per node on a tty), teeing the raw bytes into the node's
 * log file.  EOF on the pipe is the completion signal — the child (and
 * anything it spawned that inherited stdout) has exited. */
#include "sherman.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

const char *g_platform;
const char *g_sherman_dir;
const char *g_env;

/* ═══ input hashing ═════════════════════════════════════════════════════ */

/* Hash one path: its name, its permission bits (so a chmod re-runs the
 * node), and its content.  A symlink's content is its target string; a
 * regular file is streamed in 64 KB chunks so multi-hundred-MB inputs
 * never sit in memory.  Length-prefixing keeps concatenated files from
 * hashing the same as one longer file.
 *
 * Returns NULL on success or an error message.  Errors here must not
 * die(): this runs in the parent while children are in flight, and one
 * unreadable file should fail one node, not the whole run. */
static const char *hash_one_path(Sha256 *ctx, const char *path)
{
    struct stat st;
    if (lstat(path, &st) != 0)
        return xprintf("cannot stat input %s: %s", path, strerror(errno));

    sha256_update(ctx, path, strlen(path) + 1);
    uint32_t mode = st.st_mode & 07777;
    sha256_update(ctx, &mode, sizeof mode);

    if (S_ISLNK(st.st_mode)) {
        size_t len;
        char *target = read_link(path, &len);
        if (!target)
            return xprintf("cannot readlink input %s: %s", path,
                           strerror(errno));
        uint64_t encoded_len = (uint64_t)len;
        sha256_update(ctx, &encoded_len, sizeof encoded_len);
        sha256_update(ctx, target, len);
        return NULL;
    }

    if (!S_ISREG(st.st_mode))
        return NULL;                    /* fifo/socket: name+mode is enough */

    uint64_t len = (uint64_t)st.st_size;
    sha256_update(ctx, &len, sizeof len);

    int fd = open(path, O_RDONLY);
    if (fd < 0)
        return xprintf("cannot read input %s: %s", path, strerror(errno));

    char buf[64 * 1024];
    ssize_t got;
    while ((got = read(fd, buf, sizeof buf)) > 0)
        sha256_update(ctx, buf, (size_t)got);
    int read_errno = errno;
    close(fd);

    if (got < 0)
        return xprintf("cannot read input %s: %s", path, strerror(read_errno));
    return NULL;
}

/* Everything that should trigger a re-run when it changes: the change
 * SRCs and the `in` block. */
static StrList input_roots(const Node *n)
{
    StrList roots = {0};
    for (size_t i = 0; i < n->nchanges; i++)
        strlist_push(&roots, xstrdup(n->changes[i].src));
    for (size_t i = 0; i < n->ins.len; i++)
        strlist_push(&roots, n->ins.items[i]);
    return roots;
}

/* The node's input hash: sherman.md text + env name + every input file's
 * path and content (directory entries walked recursively, deterministic order).
 * A missing input sets failmsg and returns NULL — this is the presence
 * check the format promises. */
char *compute_hash(Node *n)
{
    Sha256 ctx;
    sha256_init(&ctx);
    sha256_update(&ctx, n->mdtext, strlen(n->mdtext));
    sha256_update(&ctx, g_env, strlen(g_env) + 1);

    StrList roots = input_roots(n);
    for (size_t i = 0; i < roots.len; i++) {
        struct stat st;
        if (lstat(roots.items[i], &st) != 0) {
            n->failmsg = xprintf("missing input: %s", roots.items[i]);
            return NULL;
        }

        StrList files = {0};
        const char *err = collect_files(roots.items[i], &files);
        for (size_t j = 0; !err && j < files.len; j++)
            err = hash_one_path(&ctx, files.items[j]);
        if (err) {
            n->failmsg = err;
            return NULL;
        }
    }

    if (n->always)
        return xstrdup("always");   /* inputs validated; never matches a hash */

    char *hex = xalloc(65);
    sha256_hex(&ctx, hex);
    return hex;
}

/* ═══ live output ═══════════════════════════════════════════════════════ */

static int name_width;          /* longest node name, for prefix alignment */
static bool use_color;

static int node_color(const Node *n)
{
    static const int palette[] = {36, 32, 33, 35, 34};  /* cyan..blue */
    return palette[n->idx % 5];
}

/* Print (and reset) the node's buffered partial line as "<node> | <line>". */
static void emit_line(Node *n)
{
    if (n->partial.len == 0)
        return;

    if (use_color)
        printf("\033[%dm%-*s |\033[0m %s\n", node_color(n), name_width,
               n->name, sb_str(&n->partial));
    else
        printf("%-*s | %s\n", name_width, n->name, sb_str(&n->partial));

    fflush(stdout);
    n->partial.len = 0;
}

static void log_write(int fd, const char *buf, size_t len)
{
    while (len > 0) {
        ssize_t w = write(fd, buf, len);
        if (w <= 0)
            return;             /* losing a log tail beats aborting the run */
        buf += w;
        len -= (size_t)w;
    }
}

/* Read whatever the pipe has right now: tee it to the log file, stream
 * complete lines to the terminal.  '\r' counts as a line break so
 * curl/wget style progress output stays readable.  Returns true on EOF,
 * i.e. the child has exited. */
static bool drain_pipe(Node *n)
{
    char buf[4096];
    ssize_t got = read(n->pipefd, buf, sizeof buf);

    if (got < 0) {
        if (errno == EINTR || errno == EAGAIN)
            return false;
        die("read from %s: %s", n->name, strerror(errno));
    }
    if (got == 0)
        return true;

    log_write(n->logfd, buf, (size_t)got);

    for (ssize_t i = 0; i < got; i++) {
        if (buf[i] == '\n' || buf[i] == '\r')
            emit_line(n);
        else
            sb_putc(&n->partial, buf[i]);
    }
    return false;
}

/* On failure the interleaved stream is awkward to read back, so the
 * node's full log is recapped in one block. */
static void dump_log(const char *path)
{
    char *cursor = read_file(path, NULL);
    char *line;
    while ((line = next_line(&cursor)) != NULL)
        printf("       | %s\n", line);
}

/* ═══ finishing and unlocking ═══════════════════════════════════════════ */

static NodeList ready;
static size_t nfinished, nrunning, nfailed;

/* Record a node's final status and propagate to its dependents: a success
 * unlocks them; a failure (or skip) poisons them, so when their last
 * dependency finishes they fall straight through to SKIPPED — which is
 * why this recurses. */
static void finish(Node *n, Status status)
{
    n->status = status;
    nfinished++;
    if (status == ST_FAILED)
        nfailed++;

    bool bad = (status == ST_FAILED || status == ST_SKIPPED);

    for (size_t i = 0; i < n->ndependents; i++) {
        Node *dep = n->dependents[i];
        if (bad)
            dep->poisoned = true;

        if (--dep->waiting > 0)
            continue;

        if (dep->poisoned) {
            printf("[skip] %s (a dependency failed)\n", dep->name);
            finish(dep, ST_SKIPPED);
        } else {
            PUSH(ready.items, ready.len, ready.cap, dep);
        }
    }
}

/* ═══ spawning and reaping ══════════════════════════════════════════════ */

static double seconds_since(struct timespec t0)
{
    struct timespec t1;
    clock_gettime(CLOCK_MONOTONIC, &t1);
    return (double)(t1.tv_sec - t0.tv_sec) +
           (double)(t1.tv_nsec - t0.tv_nsec) / 1e9;
}

static void spawn(Node *n)
{
    /* A log file for the tee, and a pipe for the live stream. */
    n->logpath = xprintf("%s/tmp-log-XXXXXX", state_root());
    n->logfd = mkstemp(n->logpath);
    if (n->logfd < 0)
        die("mkstemp %s: %s", n->logpath, strerror(errno));

    int pipefd[2];
    if (pipe(pipefd) != 0)
        die("pipe: %s", strerror(errno));

    clock_gettime(CLOCK_MONOTONIC, &n->started);
    printf("[run ] %s\n", n->name);
    fflush(stdout);             /* don't duplicate stdio buffers into the child */

    pid_t pid = fork();
    if (pid < 0)
        die("fork: %s", strerror(errno));

    if (pid == 0) {
        /* ── child ──
         * All output into the pipe.  stdin stays on the tty so sudo can
         * still prompt (its prompt goes to /dev/tty, not stderr). */
        dup2(pipefd[1], 1);
        dup2(pipefd[1], 2);
        close(pipefd[0]);
        close(pipefd[1]);
        close(n->logfd);

        if (chdir(n->dir) != 0) {
            perror("chdir");
            _exit(127);
        }

        apply_changes(n);       /* the copy verbs; dies into the pipe on error */

        if (n->install) {
            fflush(stdout);
            execl("/bin/bash", "bash", "-ec", n->install, (char *)NULL);
            perror("exec bash");
            _exit(127);
        }
        fflush(stdout);
        _exit(0);
    }

    /* ── parent ──
     * Close the write end now: once the child exits, the pipe hits EOF,
     * and that EOF is our completion signal. */
    close(pipefd[1]);
    n->pipefd = pipefd[0];
    n->pid = pid;
    n->status = ST_RUNNING;
    nrunning++;
}

/* The pipe hit EOF: flush the last partial line, collect the exit status,
 * record state on success, report either way. */
static void reap(Node *n)
{
    emit_line(n);
    close(n->pipefd);
    close(n->logfd);

    int status;
    while (waitpid(n->pid, &status, 0) < 0)
        if (errno != EINTR)
            die("waitpid: %s", strerror(errno));
    nrunning--;

    bool ok = WIFEXITED(status) && WEXITSTATUS(status) == 0;
    if (ok) {
        state_write(n);
        if (rename(n->logpath, xprintf("%s/%s/log", state_root(), n->name)) != 0)
            unlink(n->logpath);         /* don't orphan the tmp log */
        printf("[ ok ] %s (%.1fs)\n", n->name, seconds_since(n->started));
        finish(n, ST_OK);
    } else {
        printf("[fail] %s (%.1fs, exit %d) — output:\n", n->name,
               seconds_since(n->started),
               WIFEXITED(status) ? WEXITSTATUS(status) : 128);
        dump_log(n->logpath);
        unlink(n->logpath);
        finish(n, ST_FAILED);
    }
}

/* ═══ the scheduler ═════════════════════════════════════════════════════ */

/* Take one node off the ready list and start it.  Nodes that turn out to
 * be up to date (or have a missing input) finish right here, without a
 * child process. */
static void start_one(void)
{
    Node *n = ready.items[--ready.len];

    n->hash = compute_hash(n);
    if (!n->hash) {
        printf("[fail] %s — %s\n", n->name, n->failmsg);
        finish(n, ST_FAILED);
        return;
    }

    if (!n->always) {
        char *applied = state_read_hash(n->name);
        if (applied && strcmp(applied, n->hash) == 0 &&
            state_outputs_match(n)) {
            printf("[ = ] %s (up to date)\n", n->name);
            finish(n, ST_UP_TO_DATE);
            return;
        }
    }

    spawn(n);
}

/* Block until at least one running child produces output or exits, then
 * handle everything that's pending. */
static void pump_running_jobs(void)
{
    struct pollfd fds[64];
    Node *owner[64];
    nfds_t nfds = 0;

    for (size_t i = 0; i < all_nodes.len && nfds < 64; i++) {
        Node *n = all_nodes.items[i];
        if (n->status != ST_RUNNING)
            continue;
        fds[nfds].fd = n->pipefd;
        fds[nfds].events = POLLIN;
        fds[nfds].revents = 0;
        owner[nfds++] = n;
    }

    if (poll(fds, nfds, -1) < 0) {
        if (errno == EINTR)
            return;
        die("poll: %s", strerror(errno));
    }

    for (nfds_t i = 0; i < nfds; i++) {
        if (!(fds[i].revents & (POLLIN | POLLHUP | POLLERR)))
            continue;
        if (drain_pipe(owner[i]))
            reap(owner[i]);
    }
}

static void print_summary(void)
{
    size_t ok = 0, fresh = 0, skipped = 0;
    for (size_t i = 0; i < all_nodes.len; i++) {
        switch (all_nodes.items[i]->status) {
        case ST_OK:         ok++;      break;
        case ST_UP_TO_DATE: fresh++;   break;
        case ST_SKIPPED:    skipped++; break;
        default:                       break;
        }
    }
    printf("\n%zu applied, %zu up to date, %zu failed, %zu skipped\n",
           ok, fresh, nfailed, skipped);
}

int run_graph(int maxjobs)
{
    use_color = isatty(1);

    for (size_t i = 0; i < all_nodes.len; i++) {
        Node *n = all_nodes.items[i];
        n->idx = (int)i;
        n->status = ST_WAITING;
        n->waiting = n->ndeps;

        int w = (int)strlen(n->name);
        if (w > name_width && w <= 32)
            name_width = w;

        if (n->waiting == 0)
            PUSH(ready.items, ready.len, ready.cap, n);
    }

    while (nfinished < all_nodes.len) {
        /* Fill the job slots.  start_one may finish nodes instantly
         * (up to date), unlocking more ready work — the loop absorbs it. */
        while (nrunning < (size_t)maxjobs && ready.len > 0)
            start_one();

        if (nfinished >= all_nodes.len)
            break;
        if (nrunning == 0)
            die("internal error: scheduler stalled"); /* cycles rejected at load */

        pump_running_jobs();
    }

    print_summary();
    return (int)nfailed;
}

/* ═══ `sherman status` ══════════════════════════════════════════════════ */

void print_plan(void)
{
    for (size_t i = 0; i < all_nodes.len; i++) {
        Node *n = all_nodes.items[i];

        char *hash = compute_hash(n);
        if (!hash) {
            printf("[blocked ] %s — %s\n", n->name, n->failmsg);
            continue;
        }

        if (n->always) {
            printf("[ always ] %s\n", n->name);
            continue;
        }

        char *applied = state_read_hash(n->name);
        if (applied && strcmp(applied, hash) == 0 && state_outputs_match(n))
            printf("[up2date ] %s\n", n->name);
        else
            printf("[  run   ] %s%s\n", n->name,
                   applied ? " (changed)" : " (never applied)");
    }
}
