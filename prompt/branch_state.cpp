/**
 * @file branch_state.cpp
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <system_error>

#include "branch_state.h"
#include "color.h"

#define MAX_LINE_LENGTH 200

#define STARTSWITH(str, sub) (strncmp((str), (sub), strlen((sub))) == 0)

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
#define POPEN _popen
#define PCLOSE _pclose
#else
#define POPEN popen
#define PCLOSE pclose
#endif

#define CLEAR 0
#define CLEAN (1 << 0)
#define CONFLICT (1 << 1)
#define STAGED (1 << 2)
#define MODIFIED (1 << 3)

#define HEAD_DETACHED (1 << 4)
#define FATAL (1 << 5)

typedef unsigned char state_t;

static struct Format
{
    std::string symbols;
    color_t color = BLACK;
};

static state_t parseStatus(FILE *fp, std::string &branchName)
{
    state_t state = 0x00;
    bool branchFound = false;

    char line[MAX_LINE_LENGTH];
    char branch[MAX_BRANCH_NAME_LENGTH];

    while (fgets(line, sizeof(line), fp) != nullptr)
    {
        if (STARTSWITH(line, "fatal"))
        {
            state |= FATAL;
            return state;
        }

        if (!branchFound)
        {
            if (sscanf(line, "On branch %s", branch))
            {
                branchFound = true;
            }
            else if (sscanf(line, "HEAD detached at %s", branch))
            {
                branchFound = true;
                state |= HEAD_DETACHED;
            }
            continue;
        }

        if (STARTSWITH(line, "nothing to commit"))
        {
            state |= CLEAN;
            break;
        }

        if (STARTSWITH(line, "Changes not staged for commit") ||
            STARTSWITH(line, "Untracked files"))
        {
            state |= MODIFIED;
        }
        if (STARTSWITH(line, "Changes to be committed"))
        {
            state |= STAGED;
        }
        if (STARTSWITH(line, "Unmerged paths"))
        {
            state |= CONFLICT;
        }
    }

    if (!branchFound)
        state |= FATAL;
    else
        branchName = branch;

    return state;
}

static Format getFormat(state_t state)
{
    Format format;

    if (state & CLEAN)
    {
        format.color = GREEN;
        return;
    }
    if (state & MODIFIED)
    {
        format.symbols.append("*");
        format.color = YELLOW;
    }
    if (state & STAGED)
    {
        format.symbols.append("+");
        format.color = MAGENTA;
    }
    if (state & CONFLICT)
    {
        format.symbols.append("!");
        format.color = RED;
    }

    return format;
}

int getBranchState(std::string &branchState)
{
    FILE *fp = POPEN("git status 2>&1", "r");

    /* Failed to run `git status`.  */
    if (fp == nullptr)
        return EXIT_FAILURE;

    std::string branchName;
    state_t state = parseStatus(fp, branchName);

    PCLOSE(fp);

    /* Some fatal error occurred in parsing the output, or the directory is not
    a repository.  */
    if (state & FATAL)
        return EINVAL;

    std::string detachedPrefix = DIM "DETACHED:" END;
    if (!(state & HEAD_DETACHED))
        detachedPrefix = "";

    Format format = getFormat(state);

    /* echo "${detachedPrefix}${color}${branchName}${symbols}${END}"  */
    branchState += detachedPrefix;
    branchState += format.color;
    branchState += branchName;
    branchState += format.symbols;
    branchState += END;

    return EXIT_SUCCESS;
}
