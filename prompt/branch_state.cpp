/**
 * @file branch_state.cpp
 */

#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <system_error>

#include "branch_state.hpp"
#include "color.h"

#define MAX_LINE_LENGTH 200

#define STARTSWITH(str, sub) (strncmp((str), (sub), strlen((sub))) == 0)

#define AS_BYTE(b) (static_cast<uint8_t>((b)))

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
#define POPEN _popen
#define PCLOSE _pclose
#else
#define POPEN popen
#define PCLOSE pclose
#endif

namespace State
{
    enum Value : uint8_t
    {
        Clear = 0,
        Clean = (1 << 0),
        Conflict = (1 << 1),
        Staged = (1 << 2),
        Modified = (1 << 3),

        HeadDetached = (1 << 4),
        Fatal = (1 << 5),
    };

    inline State::Value &operator|=(State::Value &a, State::Value b)
    {
        return a = static_cast<State::Value>(AS_BYTE(a) | AS_BYTE(b));
    }

    inline constexpr State::Value operator|(State::Value &a, State::Value &b)
    {
        return static_cast<State::Value>(AS_BYTE(a) | AS_BYTE(b));
    }

    inline constexpr State::Value operator&(State::Value &a, State::Value &b)
    {
        return static_cast<State::Value>(AS_BYTE(a) & AS_BYTE(b));
    }
}

struct Format
{
    std::string symbols;
    color_t color = BLACK;
};

static State::Value parseStatus(FILE *fp, std::string &branchName)
{
    State::Value state = State::Clear;
    bool branchFound = false;

    char line[MAX_LINE_LENGTH];
    char branch[MAX_BRANCH_NAME_LENGTH];

    while (fgets(line, sizeof(line), fp) != nullptr)
    {
        if (STARTSWITH(line, "fatal"))
        {
            state |= State::Fatal;
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
                state |= State::HeadDetached;
            }
            continue;
        }

        if (STARTSWITH(line, "nothing to commit"))
        {
            state |= State::Clean;
            break;
        }

        if (STARTSWITH(line, "Changes not staged for commit") ||
            STARTSWITH(line, "Untracked files"))
        {
            state |= State::Modified;
        }
        if (STARTSWITH(line, "Changes to be committed"))
        {
            state |= State::Staged;
        }
        if (STARTSWITH(line, "Unmerged paths"))
        {
            state |= State::Conflict;
        }
    }

    if (!branchFound)
        state |= State::Fatal;
    else
        branchName = branch;

    return state;
}

static Format getFormat(State::Value state)
{
    Format format;

    if (state & State::Clean)
    {
        format.color = GREEN;
        return format;
    }
    if (state & State::Modified)
    {
        format.symbols.append("*");
        format.color = YELLOW;
    }
    if (state & State::Staged)
    {
        format.symbols.append("+");
        format.color = MAGENTA;
    }
    if (state & State::Conflict)
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
    State::Value state = parseStatus(fp, branchName);

    PCLOSE(fp);

    /* Some fatal error occurred in parsing the output, or the directory is not
    a repository.  */
    if (state & State::Fatal)
        return EINVAL;

    std::string detachedPrefix = DIM "DETACHED:" END;
    if (!(state & State::HeadDetached))
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
