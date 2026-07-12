/* graph.c — load nodes by name, wire dependency edges, reject cycles.
 *
 * Loading is a depth-first walk: load_node parses the file, then loads
 * each dependency before returning.  Cycle detection falls out of the
 * walk: a node revisited while its `loading` flag is still set can only
 * mean the walk re-entered it through its own dependencies. */
#include "sherman.h"

NodeList all_nodes;

Node *find_node(const char *name)
{
    for (size_t i = 0; i < all_nodes.len; i++)
        if (strcmp(all_nodes.items[i]->name, name) == 0)
            return all_nodes.items[i];
    return NULL;
}

/* Node identity is the name STRING (find_node is strcmp), but definition
 * lookup goes through the filesystem, which forgives spellings like
 * "a/" or "a//b".  Accepting those would create alias nodes whose state
 * entries GC would immediately undo — so reject anything non-canonical. */
static void validate_name(const char *name)
{
    size_t len = strlen(name);
    if (len == 0 || name[0] == '/')
        die("bad configset name: '%s'", name);
    if (name[len - 1] == '/')
        die("bad configset name (trailing slash): '%s'", name);
    if (strstr(name, "//") != NULL)
        die("bad configset name: '%s'", name);

    for (const char *part = name; part; ) {
        const char *slash = strchr(part, '/');
        size_t part_len = slash ? (size_t)(slash - part) : strlen(part);
        if ((part_len == 1 && part[0] == '.') ||
            (part_len == 2 && part[0] == '.' && part[1] == '.'))
            die("bad configset name: '%s'", name);
        part = slash ? slash + 1 : NULL;
    }
}

/* A dep line may be platform-scoped: "macos:macos/brew" only exists on
 * macOS machines.  Returns the bare name, or NULL when the dep does not
 * apply to this platform. */
static const char *platform_filter(const char *dep)
{
    const char *colon = strchr(dep, ':');
    if (!colon)
        return dep;

    char *platform = xstrndup(dep, (size_t)(colon - dep));
    if (strcmp(platform, "macos") != 0 && strcmp(platform, "debian") != 0)
        die("unknown platform prefix '%s' in dep '%s'", platform, dep);

    if (strcmp(platform, g_platform) != 0)
        return NULL;
    return colon + 1;
}

/* A node's definition can live in two places:
 *
 *   configsets/<name>/sherman.md    a directory configset
 *   configsets/<name>.md            a single-file node, e.g. envs/work
 *
 * Fills in dir/mdpath/mdtext; dies if neither exists. */
static void locate_definition(Node *n)
{
    const char *root = xprintf("%s/configsets", g_sherman_dir);

    n->dir = xprintf("%s/%s", root, n->name);
    n->mdpath = xprintf("%s/sherman.md", n->dir);
    n->mdtext = read_file(n->mdpath, NULL);
    if (n->mdtext)
        return;

    /* Single-file form: the node's dir is the file's parent. */
    n->mdpath = xprintf("%s/%s.md", root, n->name);
    n->mdtext = read_file(n->mdpath, NULL);
    const char *slash = strrchr(n->name, '/');
    n->dir = slash ? xprintf("%s/%.*s", root, (int)(slash - n->name), n->name)
                   : root;
    if (n->mdtext)
        return;

    die("configset '%s' not found (no %s/%s/sherman.md or %s/%s.md)",
        n->name, root, n->name, root, n->name);
}

Node *load_node(const char *name)
{
    validate_name(name);

    Node *n = find_node(name);
    if (n) {
        if (n->loading)
            die("dependency cycle through '%s'", name);
        return n;
    }

    n = xalloc(sizeof *n);
    n->name = xstrdup(name);
    n->loading = true;
    PUSH(all_nodes.items, all_nodes.len, all_nodes.cap, n);

    locate_definition(n);
    parse_node(n);

    /* Depth-first into the dependencies, wiring edges both ways: deps for
     * the scheduler's waiting counts, dependents for unlock/poison
     * propagation when this node finishes. */
    for (size_t i = 0; i < n->dep_names.len; i++) {
        const char *dep_name = platform_filter(n->dep_names.items[i]);
        if (!dep_name)
            continue;

        Node *dep = load_node(dep_name);
        PUSH(n->deps, n->ndeps, n->deps_cap, dep);
        PUSH(dep->dependents, dep->ndependents, dep->dependents_cap, n);
    }

    n->loading = false;
    return n;
}
