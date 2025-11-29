#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct String {
    char* chars;
    int size;
};

enum ValueKind {
    Number,
    Bool,
    String
};

union ValueContents {
    double f;
    int b;
    struct String* str;
};

struct Value {
    enum ValueKind kind;
    union ValueContents contents;
};

struct StackNode {
    struct StackNode* next;
    struct Value value;
};

struct StackNode* stack_node_new(struct Value value) {
    struct StackNode* node = malloc(sizeof(struct StackNode));
    node->value = value;
    node->next = NULL;
    return node;
}

void stack_node_free(struct StackNode* node) {
    // TODO: Free value contents based on kind
    free(node);
}

int main() {
    struct Value test_value = {
        .kind = Number,
        .contents.f = 42.0
    };
    struct StackNode* head = stack_node_new(test_value);
    stack_node_free(head);
    return 0;
}