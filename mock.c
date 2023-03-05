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

#define double_string(heap_string, current_capacity)                 \
    do                                                               \
    {                                                                \
        *(current_capacity) = (*(current_capacity) + 1) * 2;         \
        (heap_string) = realloc((heap_string), *(current_capacity)); \
    } while (0)

static void
mock_tokens(char const *tokens[], size_t num_tokens,
            char *heap_string, size_t *current_capacity)
{
    size_t pos = 0;
    bool toggle = false;

    for (size_t i = 0; i < num_tokens; i++)
    {
        char const *token = tokens[i];

        size_t j = 0;
        char ch = token[j];
        while (ch != '\0')
        {
            if (pos == *current_capacity)
                double_string(heap_string, current_capacity);

            heap_string[pos] = ch;
            if (isalpha(ch))
            {
                heap_string[pos] = toggle ? toggle_case(ch) : ch;
                toggle = !toggle;
            }
            ch = token[++j];
            pos++;
        }

        if (pos == *current_capacity)
            double_string(heap_string, current_capacity);
        heap_string[pos++] = ' ';
    }

    /* Since we're using values from argv, the user's final newline when hitting
    RETURN at the command line isn't included.  Thus, we account for that here
    by capping the C string with both a newline and the null character.  */
    if (pos == *current_capacity)
        realloc(heap_string, (*current_capacity += 2));

    heap_string[pos] = '\n';
    heap_string[pos + 1] = '\0';
}

static void
mock_stdin(char *heap_string, size_t *current_capacity)
{
    size_t pos = 0;
    bool toggle = false;

    int ch;
    while ((ch = getchar()) != EOF)
    {
        if (pos == *current_capacity)
            double_string(heap_string, current_capacity);

        heap_string[pos] = ch;
        if (isalpha(ch))
        {
            heap_string[pos] = (char)(toggle ? toggle_case(ch) : ch);
            toggle = !toggle;
        }
        pos++;
    }

    if (pos == *current_capacity)
        realloc(heap_string, ++(*current_capacity));
    heap_string[pos] = '\0';
}

int main(int argc, char const *argv[])
{
    size_t buffer_size = BUFFER_SIZE;
    char *result = malloc(buffer_size);

    if (argc < 2)
        mock_stdin(result, &buffer_size);
    else
        mock_tokens(&argv[1], argc - 1, result, &buffer_size);

    printf(result);

    free(result);
    return EXIT_SUCCESS;
}
