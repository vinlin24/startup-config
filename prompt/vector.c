/**
 * @file vector.c
 */

#include "vector.h"

#include <assert.h>

#define GROWTH_RATIO 1.125

#define max(x, y) ((x) > (y) ? (x) : (y))

struct vector_t
{
    char const **data;
    size_t size;
    size_t capacity;
};

static inline void vector_reallocate(vector_t *v)
{
    size_t original = v->capacity;
    /* Assert that the vector grows no matter what.  */
    v->capacity = max(original * GROWTH_RATIO, original + 1);
    v->data = realloc(v->data, v->capacity * sizeof(char const *));
}

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

inline size_t vector_size(vector_t const *v)
{
    return v->size;
}

inline char const *vector_get(vector_t const *v, size_t index)
{
    if (index >= v->size)
        return NULL;
    return v->data[index];
}

inline bool vector_set(vector_t *v, size_t index, char const *element)
{
    if (index >= v->size)
        return false;
    v->data[index] = element;
    return true;
}

void vector_append(vector_t *v, char const *element)
{
    if (v->size == v->capacity)
        vector_reallocate(v);
    v->data[v->size++] = element;
}
