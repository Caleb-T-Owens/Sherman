/* util.c — the arena allocator and the small helpers everything else
 * leans on: string building, line iteration, file reading. */
#include "sherman.h"

#include <errno.h>
#include <stdalign.h>
#include <sys/stat.h>
#include <unistd.h>

/* ═══ the arena ═════════════════════════════════════════════════════════
 *
 * A singly-linked list of malloc'd blocks.  xalloc bumps a cursor in the
 * newest block; when the request doesn't fit, a fresh block is pushed.
 * Nothing is freed until process exit — see the note in sherman.h. */

typedef struct ArenaBlock {
    struct ArenaBlock *next;
    size_t used, cap;
    _Alignas(max_align_t) unsigned char mem[];
} ArenaBlock;

static ArenaBlock *arena;

void *xalloc(size_t n)
{
    /* Round up so every allocation stays maximally aligned. */
    n = (n + alignof(max_align_t) - 1) & ~(alignof(max_align_t) - 1);

    if (!arena || arena->cap - arena->used < n) {
        size_t cap = n > 64 * 1024 ? n : 64 * 1024;
        ArenaBlock *b = malloc(sizeof *b + cap);
        if (!b) die("out of memory (%zu bytes)", n);
        b->next = arena;
        b->used = 0;
        b->cap = cap;
        arena = b;
    }

    void *p = arena->mem + arena->used;
    arena->used += n;
    memset(p, 0, n);
    return p;
}

char *xstrndup(const char *s, size_t n)
{
    char *p = xalloc(n + 1);
    memcpy(p, s, n);
    return p;                   /* xalloc zeroed the terminator for us */
}

char *xstrdup(const char *s)
{
    return xstrndup(s, strlen(s));
}

char *xprintf(const char *fmt, ...)
{
    va_list ap, ap2;
    va_start(ap, fmt);
    va_copy(ap2, ap);

    int n = vsnprintf(NULL, 0, fmt, ap);        /* measure */
    va_end(ap);
    if (n < 0) die("vsnprintf failed");

    char *p = xalloc((size_t)n + 1);
    vsnprintf(p, (size_t)n + 1, fmt, ap2);      /* fill */
    va_end(ap2);
    return p;
}

_Noreturn void die(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    fputs("sherman: ", stderr);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
    exit(1);
}

/* ═══ string builder ════════════════════════════════════════════════════ */

static void sb_reserve(StrBuf *b, size_t extra)
{
    if (b->len + extra + 1 <= b->cap)
        return;

    size_t cap = b->cap ? b->cap : 64;
    while (cap < b->len + extra + 1)
        cap *= 2;

    char *mem = xalloc(cap);
    memcpy(mem, b->s, b->len);
    b->s = mem;
    b->cap = cap;
}

void sb_putc(StrBuf *b, char ch)
{
    sb_reserve(b, 1);
    b->s[b->len++] = ch;
}

void sb_puts(StrBuf *b, const char *s)
{
    size_t n = strlen(s);
    sb_reserve(b, n);
    memcpy(b->s + b->len, s, n);
    b->len += n;
}

char *sb_str(StrBuf *b)
{
    sb_reserve(b, 0);
    b->s[b->len] = '\0';
    return b->s;
}

/* ═══ strings ═══════════════════════════════════════════════════════════ */

char *trim(char *s)
{
    while (*s == ' ' || *s == '\t' || *s == '\r' || *s == '\n')
        s++;

    char *end = s + strlen(s);
    while (end > s && (end[-1] == ' ' || end[-1] == '\t' ||
                       end[-1] == '\r' || end[-1] == '\n'))
        *--end = '\0';

    return s;
}

bool starts_with(const char *s, const char *prefix)
{
    return strncmp(s, prefix, strlen(prefix)) == 0;
}

/* Return the next line of the buffer *cursor points into, NUL-terminating
 * it in place, and advance the cursor past it.  NULL at the end.  Blank
 * lines are returned as "" — script blocks need them preserved. */
char *next_line(char **cursor)
{
    char *line = *cursor;
    if (!line || *line == '\0')
        return NULL;

    char *nl = strchr(line, '\n');
    if (nl) {
        *nl = '\0';
        *cursor = nl + 1;
    } else {
        *cursor = NULL;         /* last line had no trailing newline */
    }
    return line;
}

void strlist_push(StrList *l, char *s)
{
    PUSH(l->items, l->len, l->cap, s);
}

/* ═══ files ═════════════════════════════════════════════════════════════ */

char *read_file(const char *path, size_t *len_out)
{
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;

    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return NULL; }
    long sz = ftell(f);
    if (sz < 0) { fclose(f); return NULL; }
    rewind(f);

    char *buf = xalloc((size_t)sz + 1);         /* +1: NUL-terminated */
    size_t got = fread(buf, 1, (size_t)sz, f);
    fclose(f);

    if (got != (size_t)sz) return NULL;
    if (len_out) *len_out = got;
    return buf;
}

char *read_link(const char *path, size_t *len_out)
{
    size_t cap = 256;
    for (;;) {
        char *buf = xalloc(cap + 1);
        ssize_t n = readlink(path, buf, cap);
        if (n < 0)
            return NULL;
        if ((size_t)n < cap) {
            buf[n] = '\0';
            if (len_out) *len_out = (size_t)n;
            return buf;
        }
        cap *= 2;
    }
}

void write_file(const char *path, const char *text)
{
    FILE *f = fopen(path, "wb");
    if (!f) die("cannot write %s: %s", path, strerror(errno));

    if (fputs(text, f) == EOF || fclose(f) != 0)
        die("cannot write %s: %s", path, strerror(errno));
}

void mkdirs(const char *path)
{
    char *copy = xstrdup(path);

    /* Create each parent in turn by temporarily cutting the path short. */
    for (char *p = copy + 1; *p; p++) {
        if (*p != '/') continue;
        *p = '\0';
        if (mkdir(copy, 0755) != 0 && errno != EEXIST)
            die("mkdir %s: %s", copy, strerror(errno));
        *p = '/';
    }

    if (mkdir(copy, 0755) != 0 && errno != EEXIST)
        die("mkdir %s: %s", copy, strerror(errno));
}
