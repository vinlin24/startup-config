/**
 * @file vector.h
 * @brief Simple implementation of a string (char const *) vector.
 */

#ifndef VECTOR_H_INCLUDED
#define VECTOR_H_INCLUDED

#include <stdlib.h>

typedef struct vector_t vector_t;

vector_t *vector_init(size_t capacity);
void vector_free(vector_t *v);

#endif // VECTOR_H_INCLUDED
