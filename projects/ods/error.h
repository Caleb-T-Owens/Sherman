#pragma once

typedef struct Error {
    struct Error* next;
    char* message;
} Error;

/// Takes a copy of a string and wraps it in an Error.
Error* error(char* message);
/// Takes and owns an error and wrapps it in another Error with an additional
/// message that it copies.
Error* context(Error* e, char* context);

void unwrap(Error* self);
