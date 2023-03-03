/**
 * @file venv_state.c
 * @brief Format the Python virtual environment part of the prompt.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "color.h"
#include "vector.h"

#define MAX_OUTPUT_LENGTH 128ULL
#define MAX_VERSION_LENGTH 16ULL

typedef char const *path_t;

static int get_python_version(char *version, size_t buffer_size)
{
    // Open a pipe to run the command and capture its output
    FILE *fp = popen("python --version 2>&1", "r");
    if (fp == NULL)
        return EXIT_FAILURE;

    // Read the output of the command
    char output[MAX_OUTPUT_LENGTH];
    while (fgets(output, MAX_OUTPUT_LENGTH, fp) != NULL)
    {
        // Parse the version number from the output
        char *version_start = strstr(output, "Python ");
        if (version_start != NULL)
        {
            version_start += strlen("Python ");

            // Make sure version is null-terminated
            char *newline = strchr(version_start, '\n');
            if (newline != NULL)
                *newline = '\0';

            memcpy(version, version_start, buffer_size);
            break;
        }
    }

    int status = pclose(fp);
    if (status == -1)
        return EXIT_FAILURE;

    return status;
}

static void split_path(path_t path, vector_t *components)
{
}

int main(void)
{
    char const *VIRTUAL_ENV = getenv("VIRTUAL_ENV");
    if (VIRTUAL_ENV == NULL)
        return EXIT_SUCCESS;

    char version[MAX_VERSION_LENGTH];
    if (get_python_version(version, sizeof(version)) != EXIT_SUCCESS)
        return EXIT_FAILURE;

    vector_t *components = vector_init(10);
    split_path(VIRTUAL_ENV, components);

    /* Final formatted output to stdout.  */
    printf("%s%s%s", CYAN, version, END);

    vector_free(components);
    return EXIT_SUCCESS;
}
