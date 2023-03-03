/**
 * @file venv_state.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "color.h"

#define MAX_OUTPUT_LENGTH 128ULL
#define MAX_VERSION_LENGTH 16ULL

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

int main(void)
{
    char const *VIRTUAL_ENV = getenv("VIRTUAL_ENV");
    if (VIRTUAL_ENV == NULL)
        return EXIT_SUCCESS;

    char version[MAX_VERSION_LENGTH];
    if (get_python_version(version, sizeof(version)) != EXIT_SUCCESS)
        return EXIT_FAILURE;

    printf("%s%s%s", CYAN, version, END);
    return EXIT_SUCCESS;
}
