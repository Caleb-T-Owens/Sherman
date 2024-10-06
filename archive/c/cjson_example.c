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