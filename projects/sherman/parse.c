/* parse.c — turn a sherman.md file into a filled-in Node.
 *
 * The format is deliberately not markdown.  The whole grammar:
 *
 *   - A line starting with ``` at column 0 opens a fenced block; the rest
 *     of that line is the block's tag.  The block ends at the next line
 *     that is exactly ```.
 *   - Recognized tags (deps, in, out, change, install, uninstall, always)
 *     are live configuration.  Any other tag (```sh, ```txt, ...) and all
 *     prose outside blocks is documentation and is skipped.
 *   - Repeated blocks with the same tag concatenate.
 *
 * Parsing is one pass over the lines with a two-state machine: outside any
 * block, or inside a block of some type. */
#include "sherman.h"

/* ═══ $VAR expansion ════════════════════════════════════════════════════
 *
 * Declarative lines (change/in/out) get $VAR and ${VAR} expanded from the
 * environment.  An undefined variable is fatal: silently expanding to ""
 * is how `rm -rf $TYPO/...` accidents happen.  Install scripts are NOT
 * expanded here — they get real shell expansion when they run. */

static bool is_var_char(char ch)
{
    return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') ||
           (ch >= '0' && ch <= '9') || ch == '_';
}

/* Called with p on a '$'.  Appends the variable's value to out and returns
 * the position just past the variable name. */
static const char *expand_one_var(StrBuf *out, const char *p,
                                  const char *line, const char *ctx)
{
    p++;                                        /* skip the '$' */
    bool braced = (*p == '{');
    if (braced) p++;

    const char *start = p;
    while (is_var_char(*p))
        p++;
    if (p == start)
        die("%s: stray '$' in %s (write $NAME or ${NAME})", ctx, line);
    char *name = xstrndup(start, (size_t)(p - start));

    if (braced) {
        if (*p != '}') die("%s: unterminated ${%s", ctx, name);
        p++;
    }

    const char *value = getenv(name);
    if (!value)
        die("%s: undefined variable $%s", ctx, name);

    sb_puts(out, value);
    return p;
}

char *expand_vars(const char *line, const char *ctx)
{
    StrBuf out = {0};

    for (const char *p = line; *p; ) {
        if (*p == '$')
            p = expand_one_var(&out, p, line, ctx);
        else
            sb_putc(&out, *p++);
    }

    return sb_str(&out);
}

/* Expand, then make absolute relative to the configset directory. */
static char *resolve_path(const Node *n, const char *token)
{
    char *expanded = expand_vars(token, n->mdpath);
    if (expanded[0] == '/')
        return expanded;
    return xprintf("%s/%s", n->dir, expanded);
}

/* ═══ the block types ═══════════════════════════════════════════════════ */

typedef enum {
    BLOCK_NONE,         /* prose between fences */
    BLOCK_DEPS,
    BLOCK_IN,
    BLOCK_OUT,
    BLOCK_CHANGE,
    BLOCK_INSTALL,
    BLOCK_UNINSTALL,
    BLOCK_IGNORED,      /* a fence we skip: ```sh illustrations etc. */
} BlockType;

static BlockType classify_fence(Node *n, const char *tag)
{
    if (strcmp(tag, "deps") == 0)      return BLOCK_DEPS;
    if (strcmp(tag, "in") == 0)        return BLOCK_IN;
    if (strcmp(tag, "out") == 0)       return BLOCK_OUT;
    if (strcmp(tag, "change") == 0)    return BLOCK_CHANGE;
    if (strcmp(tag, "install") == 0)   return BLOCK_INSTALL;
    if (strcmp(tag, "uninstall") == 0) return BLOCK_UNINSTALL;

    if (strcmp(tag, "always") == 0) {
        /* Presence is the whole meaning; any content is ignored. */
        n->always = true;
        return BLOCK_IGNORED;
    }

    return BLOCK_IGNORED;
}

/* ═══ line handlers ═════════════════════════════════════════════════════ */

/* "copy SRC DST".  SRC is a single token (repo files have no spaces in
 * their names); DST is everything after it, so destinations like
 * ".../Application Support/..." need no quoting. */
static void parse_change_line(Node *n, const char *entry)
{
    char *work = xstrdup(entry);

    char *space = strchr(work, ' ');
    if (!space)
        die("%s: change line needs arguments: %s", n->mdpath, entry);
    *space = '\0';
    const char *verb = work;

    if (strcmp(verb, "copy") != 0)
        die("%s: unknown change verb '%s' (v1 knows: copy)", n->mdpath, verb);

    char *rest = trim(space + 1);
    space = strchr(rest, ' ');
    if (!space)
        die("%s: copy needs SRC and DST: %s", n->mdpath, entry);
    *space = '\0';
    const char *src = rest;
    const char *dst = trim(space + 1);

    Change change = {
        .src = resolve_path(n, src),
        .dst = expand_vars(dst, n->mdpath),
    };
    if (change.dst[0] != '/')
        die("%s: copy DST must be absolute: %s", n->mdpath, change.dst);

    PUSH(n->changes, n->nchanges, n->changes_cap, change);
}

/* One entry from a list-shaped block (deps/in/out/change). */
static void add_list_entry(Node *n, BlockType block, const char *entry)
{
    switch (block) {
    case BLOCK_DEPS:
        strlist_push(&n->dep_names, xstrdup(entry));
        break;

    case BLOCK_IN:
        strlist_push(&n->ins, resolve_path(n, entry));
        break;

    case BLOCK_OUT: {
        char *path = expand_vars(entry, n->mdpath);
        if (path[0] != '/')
            die("%s: out paths must be absolute: %s", n->mdpath, path);
        strlist_push(&n->outs, path);
        break;
    }

    case BLOCK_CHANGE:
        parse_change_line(n, entry);
        break;

    default:
        break;
    }
}

/* Script blocks keep every line verbatim, including blank ones. */
static const char *append_script_line(const char *script, const char *line)
{
    if (!script)
        return xstrdup(line);
    return xprintf("%s\n%s", script, line);
}

/* ═══ the parser ════════════════════════════════════════════════════════ */

static size_t backtick_run(const char *line)
{
    size_t n = 0;
    while (line[n] == '`')
        n++;
    return n;
}

static bool rest_is_blank(const char *p)
{
    while (*p) {
        if (*p != ' ' && *p != '\t' && *p != '\r')
            return false;
        p++;
    }
    return true;
}

void parse_node(Node *n)
{
    BlockType block = BLOCK_NONE;
    size_t fence = 0;               /* backtick count of the open fence */

    char *cursor = xstrdup(n->mdtext);          /* next_line mutates it */
    char *line;
    while ((line = next_line(&cursor)) != NULL) {
        size_t ticks = backtick_run(line);

        /* Outside a block, a run of 3+ backticks opens one; everything
         * else is prose. */
        if (fence == 0) {
            if (ticks >= 3) {
                fence = ticks;
                block = classify_fence(n, trim(line + ticks));
            }
            continue;
        }

        /* Inside a block, only a bare fence at least as long as the
         * opener closes it — so a ````-fenced script can safely contain
         * bare ``` lines (heredocs writing markdown, etc.). */
        if (ticks >= fence && rest_is_blank(line + ticks)) {
            fence = 0;
            block = BLOCK_NONE;
            continue;
        }

        if (block == BLOCK_IGNORED)
            continue;                           /* documentation */

        if (block == BLOCK_INSTALL) {
            n->install = append_script_line(n->install, line);
            continue;
        }
        if (block == BLOCK_UNINSTALL) {
            n->uninstall = append_script_line(n->uninstall, line);
            continue;
        }

        /* List-shaped blocks: one entry per line, # comments allowed. */
        const char *entry = trim(line);
        if (*entry == '\0' || *entry == '#')
            continue;
        add_list_entry(n, block, entry);
    }

    if (block != BLOCK_NONE)
        die("%s: unclosed ``` block", n->mdpath);
}
