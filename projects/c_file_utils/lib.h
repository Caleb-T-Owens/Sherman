#include <stdio.h>

// Gets the length of a file in chars
//
// It should be noted that this function as a side effect will set the file
// seek position to 0.
long fileutils_get_file_size(FILE *file);

// Reads the full contents of the file into a buffer
//
// The buffer is allocated with malloc and should be freed by the caller.
char *fileutils_file_read_all(FILE *file);

// Takes a file path and reads the full contents into a buffer.
//
// The buffer is allocated with malloc and should be freed by the caller.
// Returns NULL if the file could not be opened.
char *fileutils_path_to_string(const char *path);
