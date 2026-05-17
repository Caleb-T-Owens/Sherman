#pragma once

#include <stdlib.h>

/*
 * Push an item onto an list, where a list has the expected structure:
 * struct List<T> {
 *     T* items;
 *     size_t length;
 *     size_t capacity;
 * }
 */
#define arr_push(list, item) do {\
	if ((list)->capacity == 0) {\
		(list)->capacity = 2;\
		(list)->items = malloc(sizeof(item) * (list)->capacity);\
	} else if ((list)->length + 1 > (list)->capacity) {\
		(list)->capacity *= 2;\
		(list)->items = realloc((list)->items, sizeof(item) * (list)->capacity);\
	}\
	(list)->items[(list)->length++] = item;\
} while(false)

#define arr_foreach(list, item) for (typeof((list)->items) item = (list)->items; item < (list)->items + (list)->length; ++item)

#define arr_free(list) free(list.items)

