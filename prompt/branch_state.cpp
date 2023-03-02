/**
 * @file branch_state.cpp
 */

#include <cstdlib>
#include <cstring>
#include <cstdint>

#include <optional>
#include <sstream>

#include "branch_state.hpp"
#include "color.hpp"
#include "strings.hpp"
#include "subprocess.hpp"

#pragma region "Branch State Bit Flags"

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

#pragma endregion "Branch State Bit Flags"

#pragma region "Git Status Parsing"

struct Status
{
    State::Value state;
    std::string branchName;
};

static std::optional<Status> parseStatus(void)
{
    Subprocess gitStatus("git status 2>&1");
    std::string const &output = gitStatus.getOutput();

    Status status = {State::Clear, ""};
    bool branchFound = false;

    std::istringstream iss(output);
    std::string line;

    while (std::getline(iss, line))
    {
        if (startsWith(line, "fatal"))
            return std::nullopt;

        if (!branchFound)
        {
            auto branch = substringAfter(line, "On branch ");
            if (branch.has_value())
            {
                branchFound = true;
                status.branchName = branch.value();
                continue;
            }
            auto ref = substringAfter(line, "HEAD detached at ");
            if (ref.has_value())
            {
                branchFound = true;
                status.branchName = ref.value();
                status.state |= State::HeadDetached;
            }
            continue;
        }

        if (startsWith(line, "nothing to commit"))
        {
            status.state |= State::Clean;
            break;
        }

        if (startsWith(line, "Changes not staged for commit") ||
            startsWith(line, "Untracked files"))
        {
            status.state |= State::Modified;
        }
        if (startsWith(line, "Changes to be committed"))
        {
            status.state |= State::Staged;
        }
        if (startsWith(line, "Unmerged paths"))
        {
            status.state |= State::Conflict;
        }
    }

    if (!branchFound)
        return std::nullopt;

    return status;
}

#pragma endregion "Git Status Parsing"

#pragma region "Output Formatting"

struct Format
{
    std::string symbols;
    Color::ID color = Color::BLACK;
};

static Format getFormat(State::Value state)
{
    Format format;

    if (state & State::Clean)
    {
        format.color = Color::GREEN;
        return format;
    }
    if (state & State::Modified)
    {
        format.symbols.append("*");
        format.color = Color::YELLOW;
    }
    if (state & State::Staged)
    {
        format.symbols.append("+");
        format.color = Color::MAGENTA;
    }
    if (state & State::Conflict)
    {
        format.symbols.append("!");
        format.color = Color::RED;
    }

    return format;
}

#pragma endregion "Output Formatting"

#pragma region "Interface Function"

int getBranchState(std::string &branchState)
{
    std::optional<Status> result = parseStatus();

    /* Some fatal error occurred in parsing the output, or the directory is not
    a repository.  */
    if (!result.has_value())
        return EINVAL;
    Status const &status = result.value();

    /* If the repository is currently in deatched HEAD state, we'll want to
    include that information in the output.  */
    using namespace Color;
    std::string detachedPrefix = "";
    if (status.state & State::HeadDetached)
        detachedPrefix = ansi(DIM) + std::string("DETACHED:") + ansi(END);

    Format format = getFormat(status.state);

    /* echo "${detachedPrefix}${color}${branchName}${symbols}${END}"  */
    branchState += detachedPrefix;
    branchState += ansi(format.color);
    branchState += status.branchName;
    branchState += format.symbols;
    branchState += ansi(END);

    return EXIT_SUCCESS;
}

#pragma endregion "Interface Function"
