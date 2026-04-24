#include <stdio.h>
#include "term.h"

Error* enter_noncanon_mode(TermState* out) {
    int err;
    struct termios attrs;
    err = tcgetattr(fileno(stdin), &attrs);
    if (err) {
        return error("Failed to get tcattr");
    }

    out->attrs = attrs;

    attrs.c_lflag &= ~(ICANON);

    err = tcsetattr(fileno(stdin), TCSANOW, &attrs);
    if (err) {
        return error("Failed to set tcattr.");
    }
    return NULL;
} 

Error* leave_noncanon_mode(TermState original_attrs) {
    int err = tcsetattr(fileno(stdin), TCSANOW, &original_attrs.attrs);
    if (err) {
        return error("Failed to set tcattr.");
    }
    return NULL;
}
