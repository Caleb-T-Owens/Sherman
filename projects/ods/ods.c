#include <stdio.h>
#include <stdlib.h>
#include "error.h"
#include "term.h"

int main(int argc, char** argv) {
    TermState original_state;
    unwrap(enter_noncanon_mode(&original_state));

    char c = 0;
    while (c != 'q') {
        c = getc(stdin);

        printf("Read %c\n", c);
    }

    unwrap(leave_noncanon_mode(original_state));

    return 0;
}

