/*
 * sherman — applies configsets described by fenced blocks in sherman.md
 * files, in dependency order, in parallel, with undo tracking.
 *
 * ── Reading order for a first visit ─────────────────────────────────────
 *
 *   main.c    CLI entry point: environment setup, command dispatch.
 *   parse.c   The sherman.md format: fenced blocks → Node fields.
 *   graph.c   Names → Nodes, dependency edges, cycle rejection.
 *   run.c     Input hashing and the parallel executor. The heart.
 *   state.c   What has been applied, and how removal/undo works.
 *   verbs.c   The `copy` verb and filesystem helpers.
 *   util.c    Arena allocator, StrBuf, line iterator, small helpers.
 *   sha256.c  Reference SHA-256. Self-checking; no need to read it.
 *
 * ── Data flow of `sherman apply` ────────────────────────────────────────
 *
 *   CURRENT_ENV ─▶ load_node("envs/<env>")   (graph.c, recursive)
 *                        │ parses every reachable sherman.md into all_nodes
 *                        ▼
 *                  run_graph()               (run.c)
 *                        │ a node is ready when its deps have finished:
 *                        │   hash inputs → unchanged? skip
 *                        │   else fork a child: copy verbs, then install
 *                        │   script; stream its output live
 *                        ▼
 *                  state_write() per success (state.c)
 *                        │ hash + outs manifest + undo snapshot
 *                        ▼
 *                  gc_removed()              (state.c)
 *                          undoes state entries that left the graph
 *
 * ── Memory model ────────────────────────────────────────────────────────
 *
 * Every heap allocation comes from one global arena (util.c) and lives
 * until process exit.  Nothing is ever freed individually, so there is no
 * ownership to reason about: any pointer you hold stays valid for the rest
 * of the program.  The process is short-lived and the working set is tiny
 * (parsed text plus a small graph), so "allocate and never free" is the
 * strongest memory-safety guarantee available in C: no use-after-free, no
 * double-free, no leak that outlives the process.
 *
 * Child processes either exec a shell or _exit immediately; they never
 * touch the arena.
 */
#ifndef SHERMAN_H
#define SHERMAN_H

#if !defined(__APPLE__)
#define _XOPEN_SOURCE 700
#define _DEFAULT_SOURCE
#endif

#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <time.h>

/* ═══ util.c: arena, strings, files ════════════════════════════════════ */

void *xalloc(size_t n);                 /* arena alloc, zeroed, dies on OOM */
char *xstrdup(const char *s);
char *xstrndup(const char *s, size_t n);
char *xprintf(const char *fmt, ...);    /* asprintf into the arena */
_Noreturn void die(const char *fmt, ...); /* "sherman: ...", exit 1 */

char *trim(char *s);                    /* trims in place, returns s */
bool starts_with(const char *s, const char *prefix);

/* Iterate the lines of a mutable buffer:
 *
 *     char *cursor = text, *line;
 *     while ((line = next_line(&cursor)) != NULL) ...
 *
 * Each line is returned NUL-terminated with its '\n' removed. */
char *next_line(char **cursor);

char *read_file(const char *path, size_t *len_out);  /* NULL if unreadable */
char *read_link(const char *path, size_t *len_out);  /* NULL if unreadable */
void write_file(const char *path, const char *text);
void mkdirs(const char *path);          /* mkdir -p */

/* A growable string builder backed by the arena. Zero-initialize to use:
 *
 *     StrBuf b = {0};
 *     sb_puts(&b, "hello ");
 *     sb_putc(&b, 'x');
 *     char *s = sb_str(&b);
 */
typedef struct {
    char *s;
    size_t len, cap;
} StrBuf;

void sb_putc(StrBuf *b, char ch);
void sb_puts(StrBuf *b, const char *s);
char *sb_str(StrBuf *b);                /* NUL-terminates, returns the string */

/* A growable array of strings. */
typedef struct {
    char **items;
    size_t len, cap;
} StrList;

void strlist_push(StrList *l, char *s);

/* Grow-by-copy push for arena-backed arrays (the old copies are simply
 * abandoned in the arena — wasted bytes, not leaked ones). */
#define PUSH(arr, len, cap, item)                                        \
    do {                                                                 \
        if ((len) == (cap)) {                                            \
            size_t push_new_cap = (cap) ? (cap) * 2 : 8;                 \
            void *push_new_mem = xalloc(push_new_cap * sizeof *(arr));   \
            if (len) memcpy(push_new_mem, (arr), (len) * sizeof *(arr)); \
            (arr) = push_new_mem;                                        \
            (cap) = push_new_cap;                                        \
        }                                                                \
        (arr)[(len)++] = (item);                                         \
    } while (0)

/* ═══ sha256.c ══════════════════════════════════════════════════════════ */

typedef struct {
    uint32_t state[8];
    uint64_t nbytes;
    uint8_t buf[64];
    size_t buflen;
} Sha256;

void sha256_init(Sha256 *c);
void sha256_update(Sha256 *c, const void *data, size_t len);
void sha256_hex(Sha256 *c, char out[65]);   /* finalizes */

/* ═══ the graph ═════════════════════════════════════════════════════════ */

/* One parsed `change` line.  v1 has a single verb, "copy"; src may be a
 * file or a whole directory. */
typedef struct {
    const char *src;    /* absolute path into the repo */
    const char *dst;    /* absolute path on the machine */
} Change;

typedef enum {
    ST_WAITING,         /* dependencies not finished yet */
    ST_RUNNING,         /* child process alive */
    ST_OK,              /* applied this run */
    ST_UP_TO_DATE,      /* input hash matched — skipped */
    ST_FAILED,          /* missing input, or child exited nonzero */
    ST_SKIPPED,         /* a dependency failed, so this never ran */
} Status;

/* A configset (or an env — envs are just configsets with only deps). */
typedef struct Node Node;
struct Node {
    const char *name;       /* "macos/zsh" — relative to configsets/ */
    const char *dir;        /* absolute configset directory */
    const char *mdpath;     /* absolute path of the sherman.md */
    const char *mdtext;     /* raw file contents (part of the input hash) */

    /* parsed blocks */
    StrList dep_names;
    StrList ins;            /* extra hashed inputs, absolute */
    StrList outs;           /* declared outputs, absolute */
    Change *changes; size_t nchanges, changes_cap;
    const char *install;    /* concatenated shell text, or NULL */
    const char *uninstall;
    bool always;            /* an `always` block was present */

    /* graph edges */
    Node **deps; size_t ndeps, deps_cap;
    Node **dependents; size_t ndependents, dependents_cap;

    /* scheduling state (owned by run.c) */
    Status status;
    size_t waiting;         /* count of unfinished dependencies */
    bool poisoned;          /* some dependency failed or was skipped */
    pid_t pid;
    int pipefd;             /* read end of the child's output pipe */
    int logfd;              /* log file the parent tees output into */
    StrBuf partial;         /* buffered output up to the next newline */
    int idx;                /* position in all_nodes, for prefix colors */
    char *logpath;
    char *hash;             /* input hash, or "always" */
    const char *failmsg;    /* set instead of a log when we never spawned */
    struct timespec started;
    bool loading;           /* cycle detection during graph load */
};

typedef struct {
    Node **items;
    size_t len, cap;
} NodeList;

/* graph.c */
extern NodeList all_nodes;
Node *load_node(const char *name);      /* recursive; dies on cycle/missing */
Node *find_node(const char *name);      /* NULL if not loaded */

/* parse.c */
void parse_node(Node *n);               /* fills blocks from n->mdtext */
char *expand_vars(const char *line, const char *ctx); /* $VAR / ${VAR} */

/* run.c */
extern const char *g_platform;          /* "macos" or "debian" */
extern const char *g_sherman_dir;
extern const char *g_env;
char *compute_hash(Node *n);            /* NULL + n->failmsg on missing input */
int run_graph(int maxjobs);             /* returns count of failures */
void print_plan(void);                  /* `sherman status` */

/* state.c */
const char *state_root(void);
char *state_read_hash(const char *name);        /* NULL if none */
bool state_outputs_match(const Node *n);
void state_write(Node *n);                      /* hash, outs manifest, undo */
int gc_removed(bool dry_run);                   /* undo entries not in graph */
void sweep_stale_logs(void);                    /* clear tmp-log-* leftovers */

/* verbs.c */
void apply_changes(const Node *n);      /* runs in the child; dies on error */
int remove_tree(const char *path);
const char *collect_files(const char *path, StrList *out); /* NULL or error */

#endif
