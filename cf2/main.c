#include <stdio.h>
#include <stdlib.h>

#include "array.h"

typedef struct DependencyList
{
	struct ConfigSet *items;
	size_t length;
	size_t capacity;
} DependencyList;

typedef struct ConfigSet
{
	const char *name;
	const struct DependencyList *deps;
} ConfigSet;

int main()
{

	printf("\n");
}
