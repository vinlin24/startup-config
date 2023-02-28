/**
 * @file branch_state.c
 * @author Vincent Lin (vinlin24@outlook.com)
 * @brief Parse the output of `git status` to determine the state of the current
 * Git repository, if exists.  Print the current branch name colored and
 * suffixed with symbols mimicking the VS Code GUI notation (* for modified, +
 * for staged, etc.).  Written as a performant replacement for my
 * get_branch_state function in my .bashrc, which was a helper for determining
 * what to output for the Git part of my custom shell prompt.
 * @date 2023-02-27
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>

/* Buffer size constants.  */

#define MAX_BRANCH_LENGTH 100ULL
#define MAX_LINE_LENGTH 200ULL

/* Function macros for string manipulation.  */

#define STARTSWITH(str, sub) (strncmp((str), (sub), strlen((sub))) == 0)

/* ANSI Escape Sequences for Colored Output.  */

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

/* Flags for branch states.  */

typedef enum state_t
{
    CLEAN = 1 << 0,
    CONFLICT = 1 << 1,
    STAGED = 1 << 2,
    MODIFIED = 1 << 3,

    HEAD_DETACHED = 1 << 4,
    FATAL = 1 << 5,

} state_t;

/* Helper functions.  */

state_t parse_status(FILE *fp, char *branch_name)
{
    state_t state = 0x00;
    bool branch_found = false;

    char line_buffer[MAX_LINE_LENGTH];
    while (fgets(line_buffer, sizeof(line_buffer), fp) != NULL)
    {
        if (STARTSWITH(line_buffer, "fatal"))
        {
            state |= FATAL;
            return state;
        }

        if (!branch_found)
        {
            if (sscanf(line_buffer, "On branch %s", branch_name))
            {
                branch_found = true;
            }
            else if (sscanf(line_buffer, "HEAD detached at %s", branch_name))
            {
                branch_found = true;
                state |= HEAD_DETACHED;
            }
            continue;
        }

        if (STARTSWITH(line_buffer, "nothing to commit"))
        {
            state |= CLEAN;
            break;
        }

        if (STARTSWITH(line_buffer, "Changes not staged for commit") ||
            STARTSWITH(line_buffer, "Untracked files"))
        {
            state |= MODIFIED;
        }
        if (STARTSWITH(line_buffer, "Changes to be committed"))
        {
            state |= STAGED;
        }
        if (STARTSWITH(line_buffer, "Unmerged paths"))
        {
            state |= CONFLICT;
        }
    }

    if (!branch_found)
        state |= FATAL;

    return state;
}

void get_format(char *buffer, color_t *color, state_t state)
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

int main(int argc, char const *argv[])
{
    /* Excuse to use argc lol.  */
    if (argc > 1)
        fprintf(stderr, "%s: Ignoring command line arguments...\n", argv[0]);

    FILE *fp;
    fp = popen("git status 2>&1", "r");
    if (fp == NULL)
    {
        fprintf(stderr, "%s: Failed to run `git status`.\n", argv[0]);
        return EXIT_FAILURE;
    }

    char branch_name[MAX_BRANCH_LENGTH];
    state_t state = parse_status(fp, branch_name);

    if (state & FATAL)
    {
        fprintf(stderr, "%s: A fatal error occurred.\n", argv[0]);
        return EINVAL;
    }

    char detached_prefix[] = DIM "DETACHED:" END;
    if (!(state & HEAD_DETACHED))
        detached_prefix[0] = '\0';

    /* Zero or more of *, +, !.  Includes the null character.  */
    char symbols[4] = "";
    color_t color = BLACK;
    get_format(symbols, &color, state);

    /* Final output to stdout.  */
    printf("%s%s%s%s%s\n", detached_prefix, color, branch_name, symbols, END);

    pclose(fp);
    return EXIT_SUCCESS;
}
