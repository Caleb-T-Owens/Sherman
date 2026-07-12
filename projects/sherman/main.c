/* main.c — CLI:  sherman [-j N] <apply|status> [env]
 *
 * The env defaults to the contents of $SHERMAN_DIR/CURRENT_ENV.  An env
 * is itself a configset — configsets/envs/<env>.md — whose deps are the
 * things that machine should have. */
#include "sherman.h"

#include <errno.h>
#include <fcntl.h>
#include <sys/file.h>
#include <sys/utsname.h>

static char *read_trimmed(const char *path)
{
    char *text = read_file(path, NULL);
    return text ? trim(text) : NULL;
}

/* The variables every install/uninstall script can rely on.  Mirrors what
 * the old bin/utils/base.sh exported. */
static void setup_environment(const char *env)
{
    g_env = env;
    setenv("SHERMAN_ENV", env, 1);

    struct utsname u;
    if (uname(&u) != 0)
        die("uname failed");
    g_platform = strcmp(u.sysname, "Darwin") == 0 ? "macos" : "debian";
    setenv("SHERMAN_PLATFORM", g_platform, 1);

    char *theme = read_trimmed(xprintf("%s/THEME", g_sherman_dir));
    if (theme)
        setenv("SHERMAN_THEME", theme, 1);

    setenv("PATH", xprintf("%s/bin:%s/.cargo/bin:%s", g_sherman_dir,
                           getenv("HOME"), getenv("PATH")), 1);
}

static void usage(void)
{
    die("usage: sherman [-j N] <apply|status> [env]");
}

static void acquire_lock(void)
{
    const char *path = xprintf("%s/lock", state_root());
    int fd = open(path, O_RDWR | O_CREAT, 0600);
    if (fd < 0)
        die("open lock %s: %s", path, strerror(errno));
    if (fcntl(fd, F_SETFD, FD_CLOEXEC) != 0)
        die("configure lock %s: %s", path, strerror(errno));
    if (flock(fd, LOCK_EX | LOCK_NB) != 0)
        die("another sherman process is already running");
    /* Keep fd open for the process lifetime; closing it releases the lock. */
}

int main(int argc, char **argv)
{
    if (!getenv("HOME"))
        die("$HOME is not set");
    g_sherman_dir = getenv("SHERMAN_DIR");
    if (!g_sherman_dir)
        die("$SHERMAN_DIR is not set — run via bin/sherman");

    long jobs = 16;

    int i = 1;
    if (i < argc && strcmp(argv[i], "-j") == 0) {
        if (i + 1 >= argc)
            usage();
        char *end;
        errno = 0;
        jobs = strtol(argv[i + 1], &end, 10);
        if (errno || *end != '\0' || jobs < 1 || jobs > 64)
            die("-j must be between 1 and 64");
        i += 2;
    }
    if (i >= argc)
        usage();
    const char *cmd = argv[i++];

    const char *file_env =
        read_trimmed(xprintf("%s/CURRENT_ENV", g_sherman_dir));
    const char *env = i < argc ? argv[i++] : file_env;
    if (i != argc)
        usage();
    if (!env || !*env)
        die("no env given and no CURRENT_ENV file");

    /* GC undoes everything outside the loaded graph, so it only runs when
     * the env is the machine's own: a typo'd `sherman apply <env>` must
     * not uninstall the real env's world. */
    bool gc_safe = file_env && strcmp(file_env, env) == 0;

    setup_environment(env);
    load_node(xprintf("envs/%s", env));     /* pulls in the whole graph */

    if (strcmp(cmd, "status") == 0) {
        print_plan();
        if (gc_safe)
            gc_removed(true);   /* dry run: report what apply would undo */
        else if (!file_env)
            printf("[ gc ] would be skipped: CURRENT_ENV is missing\n");
        else
            printf("[ gc ] would be skipped: env '%s' differs from "
                   "CURRENT_ENV '%s'\n", env, file_env);
        return 0;
    }
    if (strcmp(cmd, "apply") == 0) {
        mkdirs(state_root());
        acquire_lock();
        sweep_stale_logs();
        int failures = run_graph((int)jobs);
        int gc_failures = 0;
        if (!file_env)
            printf("[ gc ] skipped: CURRENT_ENV is missing\n");
        else if (!gc_safe)
            printf("[ gc ] skipped: env '%s' differs from CURRENT_ENV "
                   "'%s'\n", env, file_env);
        else if (failures)
            printf("[ gc ] deferred: apply failed; old state was kept\n");
        else
            gc_failures = gc_removed(false);
        return failures || gc_failures ? 1 : 0;
    }
    usage();
}
