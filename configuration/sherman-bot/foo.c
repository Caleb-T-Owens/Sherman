#include "foo.h"

static char* private();

char* message() {
    return private();
}

static char* private() {
    return "Best string";
}