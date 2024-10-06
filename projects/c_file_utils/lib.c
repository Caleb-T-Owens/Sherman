#include <stdio.h>
#include <stdlib.h>

#include "lib.h"

long fileutils_get_file_size(FILE *file)
{
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fseek(file, 0, SEEK_SET);

    return size;
}

char *fileutils_file_read_all(FILE *file)
{
    long size = fileutils_get_file_size(file);

    char *buffer = malloc(size);
    fread(buffer, 1, size, file);

    return buffer;
}

char *fileutils_path_to_string(const char *path)
{
    FILE *file = fopen(path, "r");
    if (file == NULL)
    {
        return NULL;
    }

    char *buffer = fileutils_file_read_all(file);

    fclose(file);

    return buffer;
}
