#include "foo.h"

static char *private(void);

char *message(void)
{
    return private();
}

static char *private(void)
{
    return "Best string";
}
