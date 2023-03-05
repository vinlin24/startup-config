/**
 * @file branch_state.c
 * @brief Format the Git part of the prompt.
 */

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "color.h"

/* Buffer size constants.  */

/* Maximum expected length of a line of Git output, null character included.  */
#define MAX_LINE_LENGTH 200ULL

/* Maximum expected length of a Git branch name, null character included.  */
#define MAX_BRANCH_NAME_LENGTH 100ULL

/* Branch name (null character included) + DETACHED prefix + ANSI color
+ all symbols + ANSI reset.  */
#define MAX_BRANCH_STATE_LENGTH (MAX_BRANCH_NAME_LENGTH + 17 + 5 + 3 + 4 + 1)

/* Function macros for string manipulation.  */

#define STARTSWITH(str, sub) (strncmp((str), (sub), strlen((sub))) == 0)

/* Flags for branch states.  */

typedef enum state_t
{
    CLEAN = 1 << 0,
    CONFLICT = 1 << 1,
    STAGED = 1 << 2,
    UNTRACKED = 1 << 3,
    MODIFIED = 1 << 4,

    HEAD_DETACHED = 1 << 5,
    FATAL = 1 << 6,

} state_t;

typedef struct status_t
{
    char branch_name[MAX_BRANCH_NAME_LENGTH];
    state_t state;
} status_t;

/* Helper functions.  */

static status_t parse_status(FILE *fp)
{
    status_t status;
    status.branch_name[0] = '\0';
    status.state = 0x00;

    bool branch_found = false;

    char line_buffer[MAX_LINE_LENGTH];
    while (fgets(line_buffer, sizeof(line_buffer), fp) != NULL)
    {
        if (STARTSWITH(line_buffer, "fatal"))
        {
            status.state |= FATAL;
            return status;
        }

        if (!branch_found)
        {
            if (sscanf(line_buffer, "On branch %s",
                       status.branch_name))
            {
                branch_found = true;
            }
            else if (sscanf(line_buffer, "HEAD detached at %s",
                            status.branch_name))
            {
                branch_found = true;
                status.state |= HEAD_DETACHED;
            }
            continue;
        }

        if (STARTSWITH(line_buffer, "nothing to commit"))
        {
            status.state |= CLEAN;
            break;
        }

        if (STARTSWITH(line_buffer, "Changes not staged for commit"))
            status.state |= MODIFIED;
        if (STARTSWITH(line_buffer, "Untracked files"))
            status.state |= UNTRACKED;
        if (STARTSWITH(line_buffer, "Changes to be committed"))
            status.state |= STAGED;
        if (STARTSWITH(line_buffer, "Unmerged paths"))
            status.state |= CONFLICT;
    }

    if (!branch_found)
        status.state |= FATAL;

    return status;
}

static void get_format(char *buffer, color_t *color, state_t state)
{
    buffer[0] = '\0';
    if (state & CLEAN)
    {
        *color = GREEN;
        return;
    }
    if (state & MODIFIED)
    {
        strcat(buffer, "*");
        *color = YELLOW;
    }
    if (state & UNTRACKED)
    {
        strcat(buffer, "%");
        *color = YELLOW;
    }
    if (state & STAGED)
    {
        strcat(buffer, "+");
        *color = MAGENTA;
    }
    if (state & CONFLICT)
    {
        strcat(buffer, "!");
        *color = RED;
    }
}

/* Main routine.  */

int main(void)
{
    FILE *fp = popen("git status 2>&1", "r");
    /* Failed to run `git status`.  */
    if (fp == NULL)
        return EXIT_FAILURE;

    status_t status = parse_status(fp);

    /* Failed to clean up pipe.  */
    if (pclose(fp) != EXIT_SUCCESS)
        return EXIT_FAILURE;

    /* Some fatal error occurred in parsing the output, or the directory is not
    a repository.  */
    if (status.state & FATAL)
        return EINVAL;

    char detached_prefix[] = DIM "DETACHED:" END;
    if (!(status.state & HEAD_DETACHED))
        detached_prefix[0] = '\0';

    /* Zero or more of *, +, %, !.  Includes the null character.  */
    char symbols[5] = "";
    color_t color = BLACK;
    get_format(symbols, &color, status.state);

    /* Final output to stdout.  */
    printf("%s%s%s%s%s",
           detached_prefix, color, status.branch_name, symbols, END);

    return EXIT_SUCCESS;
}
