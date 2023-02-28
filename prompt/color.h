/**
 * @file color.h
 * @brief Output-related coloring with ANSI escape sequences.
 */

#ifndef COLOR_H_INCLUDED
#define COLOR_H_INCLUDED

#define BLACK "\x1b[30m"
#define RED "\x1b[31m"
#define GREEN "\x1b[32m"
#define YELLOW "\x1b[33m"
#define BLUE "\x1b[34m"
#define MAGENTA "\x1b[35m"
#define CYAN "\x1b[36m"
#define WHITE "\x1b[37m"
#define DIM "\x1b[2m"
#define END "\x1b[0m"

typedef char const *color_t;

#endif // COLOR_H_INCLUDED
