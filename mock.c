/**
 * @file mock.c
 * @author Vincent Lin (vinlin24@outlook.com)
 * @brief Simple program that converts an input string into a version with
 * alternating capitalization as used in sarcastic texting.
 * @date 2023-02-27
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <errno.h>

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

static inline char toggle_char(char ch)
{
    if (isupper(ch))
        return tolower(ch);
    return toupper(ch);
}

int main(int argc, char const *argv[])
{
    if (argc < 2)
    {
        fprintf(stderr, "%s: Expected at least one argument.\n", argv[0]);
        return EINVAL;
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
            combined[i] = toggle ? toggle_char(current_char) : current_char;
            toggle = !toggle;
        }
    }
    printf("%s\n", combined);

    free(combined);
    return EXIT_SUCCESS;
}
