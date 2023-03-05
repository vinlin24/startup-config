/**
 * @file mock.c
 * @author Vincent Lin (vinlin24@outlook.com)
 * @brief Simple program that converts an input string into a version with
 * alternating capitalization as used in sarcastic texting.
 * @date 2023-02-27
 */

#include <ctype.h>
#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 1024

#define toggle_case(ch) (isupper((ch)) ? tolower((ch)) : toupper((ch)))

static void
combine_args(int argc, char const *argv[], char *combined, size_t num_bytes)
{
    strcpy(combined, argv[1]);
    for (int i = 2; i < argc; i++)
    {
        strcat(combined, " ");
        strcat(combined, argv[i]);
    }
    combined[num_bytes - 1] = '\0';
}

static void
read_from_stdin(char *heap_string, size_t *current_capacity)
{
    size_t pos = 0;
    int ch;
    while ((ch = getchar()) != EOF)
    {
        if (pos == *current_capacity)
        {
            *current_capacity = (*current_capacity + 1) * 2;
            realloc(heap_string, *current_capacity);
        }
        heap_string[pos++] = ch;
    }

    if (pos == *current_capacity)
        realloc(heap_string, *current_capacity + 1);
    heap_string[pos] = '\0';
}

int main(int argc, char const *argv[])
{
    if (argc < 2)
    {
        fprintf(stderr, "%s: Reading from stdin: ", argv[0]);
        size_t current_size = BUFFER_SIZE;
        char *heap_string = malloc(current_size);
        read_from_stdin(heap_string, &current_size);
        printf("%s\n", heap_string);
        return EXIT_SUCCESS;
    }

    size_t length_sum = 0;
    for (int i = 1; i < argc; i++)
        length_sum += strlen(argv[i]);

    /* The lengths of the tokens + number of spaces + null character.  */
    size_t buffer_size = length_sum + (argc - 2) + 1;
    char *combined = malloc(buffer_size);
    combine_args(argc, argv, combined, buffer_size);

    bool toggle = false;
    for (size_t i = 0; i < buffer_size; i++)
    {
        char current_char = combined[i];
        if (isalpha(current_char))
        {
            combined[i] = toggle ? toggle_case(current_char) : current_char;
            toggle = !toggle;
        }
    }
    printf("%s\n", combined);

    free(combined);
    return EXIT_SUCCESS;
}
