/**
 * @file branch_state.cpp
 */

#include <cstdlib>
#include <cstring>
#include <cstdint>

#include <optional>
#include <sstream>
#include <system_error>

#include "branch_state.hpp"
#include "subprocess.hpp"
#include "color.h"

#define AS_BYTE(b) (static_cast<uint8_t>((b)))

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

static inline bool
startsWith(std::string const &string, std::string const &prefix)
{
    std::size_t pos = string.rfind(prefix, 0);
    return pos == 0;
}

static inline std::optional<std::string>
substringAfter(std::string const &string, std::string const &prefix)
{
    std::size_t pos = string.find(prefix);
    if (pos != std::string::npos)
        return string.substr(pos + prefix.size());
    return std::nullopt;
}

static State::Value parseStatus(std::string &branchName)
{
    Subprocess gitStatus("git status 2>&1");
    std::string const &output = gitStatus.getOutput();

    State::Value state = State::Clear;
    bool branchFound = false;

    std::istringstream iss(output);
    std::string line;

    while (std::getline(iss, line))
    {
        if (startsWith(line, "fatal"))
        {
            state |= State::Fatal;
            return state;
        }

        if (!branchFound)
        {
            auto branch = substringAfter(line, "On branch ");
            if (branch.has_value())
            {
                branchFound = true;
                branchName = branch.value();
                continue;
            }
            auto ref = substringAfter(line, "HEAD detached at ");
            if (ref.has_value())
            {
                branchFound = true;
                branchName = ref.value();
                state |= State::HeadDetached;
            }
            continue;
        }

        if (startsWith(line, "nothing to commit"))
        {
            state |= State::Clean;
            break;
        }

        if (startsWith(line, "Changes not staged for commit") ||
            startsWith(line, "Untracked files"))
        {
            state |= State::Modified;
        }
        if (startsWith(line, "Changes to be committed"))
        {
            state |= State::Staged;
        }
        if (startsWith(line, "Unmerged paths"))
        {
            state |= State::Conflict;
        }
    }

    if (!branchFound)
        state |= State::Fatal;

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
    std::string branchName;
    State::Value state = parseStatus(branchName);

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
