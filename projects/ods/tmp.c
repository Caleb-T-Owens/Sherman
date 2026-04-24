typedef struct {
    char* items;
    unsigned int length;
    unsigned int capacity;
} String;

String string_new(void) {
    String s;
    s.items = malloc(0);
    s.length = 0;
    s.capacity = 0;
    return s;
}

Error* string_resize(String* self, int capacity) {
    if (capacity < self->length) {
        return error("Cannot resize string to be less than it's length.");
    }
    self->items = realloc(self->items, self->capacity * sizeof(char));
    self->capacity = capacity;
    return NULL;
}

Error* string_push_char(String* self, char c) {
    if (self->capacity <= self->length) {
        Error* e = string_resize(self, ++self->capacity);
        if (e) return context(e, "Failed to resize while pushing char");
    }
    self->items[self->length] = c;
    self->length += 1;
    return NULL;
}

/* Returns the internal "items" array, terminated with a null byte at the
 * `s.length` position.
 */
Error* string_view(String* self, char** out) {
    if (self->capacity == self->length) {
        Error* e = string_resize(self, ++self->capacity);
        if (e) return context(e, "Failed to resize while growing string to include NULL byte");
    }
    self->items[self->length] = '\0';
    out = &self->items;
    return NULL;
}

void string_free(String self) {
    free(self.items);
}
