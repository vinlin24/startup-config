/**
 * @file test_vector.c
 * @brief Simple sanity checker for my vector helper struct.
 */

#include <stdio.h>
#include <stdlib.h>

#include "vector.h"

static void dump_vector(vector_t const *v)
{
    printf("[ ");
    size_t size = vector_size(v);
    for (size_t i = 0; i < size; i++)
        printf("\"%s\" ", vector_get(v, i));
    printf("]\n");
}

int main(int argc, char const *argv[])
{
    vector_t *v = vector_init(4);

    for (int i = 1; i < argc; i++)
        vector_append(v, argv[i]);

    dump_vector(v);
    return EXIT_SUCCESS;
}
