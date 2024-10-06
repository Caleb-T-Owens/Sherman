#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cJSON/cJSON.h"

#include "foo.h"

void json_example(void)
{
    // After this, any objects that we got out of the root object is also
    // cleaned up.

    const char *str = "{\"key\": \"value - yeah!\"}";
    cJSON *json = cJSON_Parse(str);

    cJSON *value = cJSON_GetObjectItem(json, "key");

    printf("Value: %s\n", value->valuestring);

    printf("%s\n", message());

    cJSON_Delete(json);
}

char *read_file_all(FILE *file)
{
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *buffer = malloc(size);
    fread(buffer, 1, size, file);

    return buffer;
}

int main(void)
{
    FILE *file = fopen("testfile", "r");

    char *str = read_file_all(file);

    printf("File contents: %s\n", str);

    free(str);

    fclose(file);

    return 0;
}
