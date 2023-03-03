/**
 * @file vector.c
 */

#include "vector.h"

#include <assert.h>

struct vector_t
{
    char const **data;
    size_t size;
    size_t capacity;
};

vector_t *vector_init(size_t capacity)
{
    assert(capacity > 0);
    vector_t *v = malloc(sizeof(vector_t));
    v->data = calloc(capacity, sizeof(char const *));
    v->size = 0;
    v->capacity = capacity;
    return v;
}

void vector_free(vector_t *v)
{
    free(v->data);
    free(v);
}
