/*
 * configure - A minimal configset runner for Sherman
 * 
 * Reads configurable.conf files from configsets/ and executes them
 * with proper dependency resolution via topological sort.
 * 
 * Usage:
 *   configure                    - list available tasks
 *   configure ./configurable.conf - run a specific config file
 *   configure -t task            - run a task by name
 *   configure -t task --no-deps  - run without dependencies
 *   configure -l                 - list available tasks
 * 
 * Config format (configurable.conf):
 *   name: shared/git
 *   script: ./install.sh
 *   deps: shared/brew shared/rustup
 */

#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <errno.h>

#define MAX_TASKS 256
#define MAX_DEPS 32
#define MAX_NAME 128
#define MAX_PATH 512
#define MAX_LINE 1024

typedef struct {
    char name[MAX_NAME];
    char script[MAX_PATH];
    char dir[MAX_PATH];
    char deps[MAX_DEPS][MAX_NAME];
    int dep_count;
    int completed;
    int visiting;
} Task;

typedef struct {
    Task tasks[MAX_TASKS];
    int count;
    char completed_names[MAX_TASKS][MAX_NAME];
    int completed_count;
} TaskList;

/* Trim leading/trailing whitespace */
static char *trim(char *s) {
    while (*s == ' ' || *s == '\t') s++;
    char *end = s + strlen(s) - 1;
    while (end > s && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r'))
        *end-- = '\0';
    return s;
}

/* Parse space-separated dependencies */
static void parse_deps(char *value, Task *task) {
    char *saveptr;
    char *token = strtok_r(value, " \t", &saveptr);
    while (token && task->dep_count < MAX_DEPS) {
        if (*token) {
            strncpy(task->deps[task->dep_count++], token, MAX_NAME - 1);
        }
        token = strtok_r(NULL, " \t", &saveptr);
    }
}

/* Parse a configurable.conf file */
static int parse_config(const char *path, Task *task) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    
    char line[MAX_LINE];
    
    /* Extract directory from path */
    strncpy(task->dir, path, MAX_PATH - 1);
    char *last_slash = strrchr(task->dir, '/');
    if (last_slash) *last_slash = '\0';
    else strcpy(task->dir, ".");
    
    task->dep_count = 0;
    task->completed = 0;
    task->visiting = 0;
    task->name[0] = '\0';
    task->script[0] = '\0';
    
    while (fgets(line, sizeof(line), f)) {
        char *trimmed = trim(line);
        
        /* Skip empty lines and comments */
        if (!*trimmed || *trimmed == '#') continue;
        
        /* Check for key: value pairs */
        char *colon = strchr(trimmed, ':');
        if (colon) {
            *colon = '\0';
            char *key = trim(trimmed);
            char *value = trim(colon + 1);
            
            if (strcmp(key, "name") == 0) {
                strncpy(task->name, value, MAX_NAME - 1);
            } else if (strcmp(key, "script") == 0) {
                strncpy(task->script, value, MAX_PATH - 1);
            } else if (strcmp(key, "deps") == 0) {
                parse_deps(value, task);
            }
        }
    }
    
    fclose(f);
    return (task->name[0] && task->script[0]) ? 0 : -1;
}

/* Find task by name */
static Task *find_task(TaskList *list, const char *name) {
    for (int i = 0; i < list->count; i++) {
        if (strcmp(list->tasks[i].name, name) == 0)
            return &list->tasks[i];
    }
    return NULL;
}

/* Check if task is already completed */
static int is_completed(TaskList *list, const char *name) {
    for (int i = 0; i < list->completed_count; i++) {
        if (strcmp(list->completed_names[i], name) == 0)
            return 1;
    }
    return 0;
}

/* Mark task as completed */
static void mark_completed(TaskList *list, const char *name) {
    if (list->completed_count < MAX_TASKS) {
        strncpy(list->completed_names[list->completed_count++], name, MAX_NAME - 1);
    }
}

/* Execute a task's script */
static int run_task(Task *task) {
    printf("\n\033[1;34m=== Running: %s ===\033[0m\n", task->name);
    printf("Directory: %s\n", task->dir);
    printf("Script: %s\n\n", task->script);
    
    pid_t pid = fork();
    if (pid < 0) {
        perror("fork");
        return -1;
    }
    
    if (pid == 0) {
        if (chdir(task->dir) < 0) {
            perror("chdir");
            exit(1);
        }
        execl("/bin/bash", "bash", "-e", task->script, NULL);
        perror("execl");
        exit(1);
    }
    
    int status;
    waitpid(pid, &status, 0);
    
    if (WIFEXITED(status) && WEXITSTATUS(status) == 0) {
        printf("\033[1;32m=== Completed: %s ===\033[0m\n", task->name);
        return 0;
    } else {
        printf("\033[1;31m=== Failed: %s (exit %d) ===\033[0m\n", 
               task->name, WIFEXITED(status) ? WEXITSTATUS(status) : -1);
        return -1;
    }
}

/* Topological sort with cycle detection */
static int run_with_deps(TaskList *list, Task *task) {
    if (is_completed(list, task->name)) return 0;
    
    if (task->visiting) {
        fprintf(stderr, "Error: Circular dependency detected at '%s'\n", task->name);
        return -1;
    }
    
    task->visiting = 1;
    
    for (int i = 0; i < task->dep_count; i++) {
        Task *dep = find_task(list, task->deps[i]);
        if (!dep) {
            fprintf(stderr, "Warning: Dependency '%s' not found for '%s'\n", 
                    task->deps[i], task->name);
            continue;
        }
        if (run_with_deps(list, dep) < 0) return -1;
    }
    
    task->visiting = 0;
    
    if (run_task(task) < 0) return -1;
    
    mark_completed(list, task->name);
    return 0;
}

/* Discover all configurable.conf files in a directory tree */
static int discover_tasks(const char *basedir, TaskList *list) {
    char configsets_path[MAX_PATH];
    snprintf(configsets_path, sizeof(configsets_path), "%s/configsets", basedir);
    
    const char *subdirs[] = {"shared", "macos", "debian", NULL};
    
    for (int s = 0; subdirs[s]; s++) {
        char subdir_path[MAX_PATH];
        snprintf(subdir_path, sizeof(subdir_path), "%s/%s", configsets_path, subdirs[s]);
        
        DIR *dir = opendir(subdir_path);
        if (!dir) continue;
        
        struct dirent *entry;
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_name[0] == '.') continue;
            
            char config_path[MAX_PATH];
            snprintf(config_path, sizeof(config_path), "%s/%s/configurable.conf",
                     subdir_path, entry->d_name);
            
            struct stat st;
            if (stat(config_path, &st) == 0 && S_ISREG(st.st_mode)) {
                if (list->count < MAX_TASKS) {
                    if (parse_config(config_path, &list->tasks[list->count]) == 0) {
                        list->count++;
                    }
                }
            }
        }
        closedir(dir);
    }
    
    return list->count;
}

/* List all available tasks */
static void list_tasks(TaskList *list) {
    printf("Available tasks (%d):\n\n", list->count);
    
    for (int i = 0; i < list->count; i++) {
        Task *t = &list->tasks[i];
        printf("  \033[1m%-30s\033[0m", t->name);
        if (t->dep_count > 0) {
            printf(" -> ");
            for (int j = 0; j < t->dep_count; j++) {
                printf("%s%s", t->deps[j], j < t->dep_count - 1 ? ", " : "");
            }
        }
        printf("\n");
    }
}

/* Get base directory - check ./configsets first, then SHERMAN_DIR, then $HOME/Sherman */
static const char *get_base_dir(void) {
    struct stat st;
    
    /* Check ./configsets first (Ralph learning!) */
    if (stat("./configsets", &st) == 0 && S_ISDIR(st.st_mode)) {
        return ".";
    }
    
    /* Check SHERMAN_DIR */
    const char *dir = getenv("SHERMAN_DIR");
    if (dir) {
        char path[MAX_PATH];
        snprintf(path, sizeof(path), "%s/configsets", dir);
        if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
            return dir;
        }
    }
    
    /* Fallback to $HOME/Sherman */
    const char *home = getenv("HOME");
    if (home) {
        static char default_dir[MAX_PATH];
        snprintf(default_dir, sizeof(default_dir), "%s/Sherman", home);
        char path[MAX_PATH];
        snprintf(path, sizeof(path), "%s/configsets", default_dir);
        if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
            return default_dir;
        }
    }
    
    return ".";
}

static void usage(const char *prog) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "  %s                       List available tasks\n", prog);
    fprintf(stderr, "  %s <configurable.conf>   Run a specific config file\n", prog);
    fprintf(stderr, "  %s -t <task>             Run a task by name\n", prog);
    fprintf(stderr, "  %s -t <task> --no-deps   Run without dependencies\n", prog);
    fprintf(stderr, "  %s -l, --list            List available tasks\n", prog);
    fprintf(stderr, "  %s -h, --help            Show this help\n", prog);
}

int main(int argc, char **argv) {
    TaskList list = {0};
    const char *target_task = NULL;
    int no_deps = 0;
    int list_only = 0;
    const char *config_file = NULL;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-t") == 0 || strcmp(argv[i], "--task") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "Error: -t requires a task name\n");
                return 1;
            }
            target_task = argv[i];
        } else if (strcmp(argv[i], "--no-deps") == 0) {
            no_deps = 1;
        } else if (strcmp(argv[i], "-l") == 0 || strcmp(argv[i], "--list") == 0) {
            list_only = 1;
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            usage(argv[0]);
            return 0;
        } else if (argv[i][0] != '-') {
            config_file = argv[i];
        } else {
            fprintf(stderr, "Unknown option: %s\n", argv[i]);
            usage(argv[0]);
            return 1;
        }
    }
    
    if (config_file) {
        Task task;
        if (parse_config(config_file, &task) < 0) {
            fprintf(stderr, "Error: Could not parse '%s'\n", config_file);
            return 1;
        }
        discover_tasks(get_base_dir(), &list);
        if (!find_task(&list, task.name) && list.count < MAX_TASKS) {
            list.tasks[list.count++] = task;
        }
        Task *t = find_task(&list, task.name);
        if (!t) t = &task;
        
        if (no_deps) return run_task(t);
        return run_with_deps(&list, t);
    }
    
    const char *base_dir = get_base_dir();
    if (discover_tasks(base_dir, &list) == 0) {
        fprintf(stderr, "No tasks found in %s/configsets/\n", base_dir);
        fprintf(stderr, "Set SHERMAN_DIR or run from a Sherman directory.\n");
        return 1;
    }
    
    if (list_only) {
        list_tasks(&list);
        return 0;
    }
    
    if (target_task) {
        Task *task = find_task(&list, target_task);
        if (!task) {
            fprintf(stderr, "Error: Task '%s' not found\n", target_task);
            fprintf(stderr, "Use -l to list available tasks.\n");
            return 1;
        }
        if (no_deps) return run_task(task) < 0 ? 1 : 0;
        return run_with_deps(&list, task) < 0 ? 1 : 0;
    }
    
    list_tasks(&list);
    printf("\nUse -t <task> to run a task, or -h for help.\n");
    return 0;
}
