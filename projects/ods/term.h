#pragma once

#include <termios.h>
#include "error.h"

typedef struct {
    struct termios attrs;
} TermState;


Error* enter_noncanon_mode(TermState* out);
Error* leave_noncanon_mode(TermState original_attrs);
