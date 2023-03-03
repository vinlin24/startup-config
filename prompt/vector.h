/**
 * @file vector.h
 * @brief Simple implementation of a string (char const *) vector.
 */

#ifndef VECTOR_H_INCLUDED
#define VECTOR_H_INCLUDED

#include <stdlib.h>
#include <stdbool.h>

typedef struct vector_t vector_t;

vector_t *vector_init(size_t capacity);
void vector_free(vector_t *v);

size_t vector_size(vector_t const *v);
char const *vector_get(vector_t const *v, size_t index);
bool vector_set(vector_t *v, size_t index, char const *element);
void vector_append(vector_t *v, char const *element);
char const *vector_pop(vector_t *v);

#endif // VECTOR_H_INCLUDED
