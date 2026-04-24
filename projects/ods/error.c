#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "error.h"

Error* error(char* message) {
    Error* e = malloc(sizeof(Error));
    e->next = NULL;
    e->message = malloc(strlen(message) + 1);
    strcpy(e->message, message);

    return e;
}

Error* context(Error* e, char* context) {
    if (!e) return NULL;

    Error* current = error(context);
    current->next = e;

    return current;
}

void unwrap(Error* self) {
    if (self) {
        Error* e = self;
        fprintf(stderr, "Unwrapping error:\n");
        while (e) {
            fprintf(stderr, "  %s\n", e->message);
            e = e->next;
        }
        exit(1);
    }
}
