#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../cJSON/cJSON.h"
#include "../c_file_utils/lib.h"

#include "json.h"

cJSON *read_json_file(const char *path)
{
    char *str = fileutils_path_to_string(path);

    if (str == NULL)
    {
        return NULL;
    }

    cJSON *json = cJSON_Parse(str);

    free(str);

    return json;
}

int main(void)
{

    cJSON *object = read_json_file("testfile");

    if (object == NULL)
    {
        printf("Failed to read file\n");
        return 1;
    }

    printf("File contents: %s\n", cJSON_GetObjectItem(object, "editor.fontFamily")->valuestring);

    cJSON_Delete(object);

    return 0;
}
