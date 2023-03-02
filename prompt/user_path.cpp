/**
 * @file user_path.cpp
 */

#include <cstdlib>
#include <filesystem>
#include <optional>
#include <stdexcept>
#include <vector>

#include "color.hpp"
#include "strings.hpp"
#include "user_path.hpp"

namespace fs = std::filesystem;

static std::optional<fs::path> relativeFromHome(fs::path const &fullPath)
{
    char const *HOME = getenv("HOME");
    if (HOME == nullptr)
        return std::nullopt;

    std::optional<std::string>
        result = substringAfter(fullPath.string(), HOME);

    if (!result.has_value())
        return std::nullopt;
    std::string &subpath = result.value();

    /* Exclude leading separator.  */
    if (!subpath.empty())
        subpath = subpath.substr(1);
    return fs::path(subpath);
}

static void appendLastTwoComponents(fs::path &base, fs::path const &source)
{
    std::vector<fs::path> components;
    for (fs::path const &component : source)
        components.push_back(component);

    if (components.empty())
        return;
    if (components.size() <= 2)
    {
        base /= source;
        return;
    }

    fs::path &current = components.end()[-1];
    fs::path &parent = components.end()[-2];
    base = base / "..." / parent / current;
}

static std::string abbreviatePath(fs::path const &fullPath)
{
    fs::path abbreviation;

    std::optional<fs::path> result = relativeFromHome(fullPath);
    fs::path subpath;

    /* We're under the home directory, so use ~ as the first  */
    if (result.has_value())
    {
        subpath = result.value();
        abbreviation += "~";
    }

    /* We're not under the home directory, so use root as the first.  */
    else
    {
        fs::path root = fullPath.root_path();
        abbreviation += root;

        fs::path afterRoot = fs::relative(fullPath, root);
        if (afterRoot.string() != ".")
            subpath = afterRoot;
    }

    appendLastTwoComponents(abbreviation, subpath);
    return abbreviation.string();
}

int getUserPath(std::string &userPath)
{
    std::string username = "?";
    std::string hostname = "?";

    bool envError = false;

    char const *USERNAME = getenv("USERNAME");
    if (USERNAME != nullptr)
    {
        username = USERNAME;
        envError = true;
    }

    char const *HOSTNAME = getenv("HOSTNAME");
    if (HOSTNAME != nullptr)
    {
        hostname = HOSTNAME;
        envError = true;
    }

    fs::path cwd = fs::current_path();

    userPath += Color::wrap(username + "@" + hostname, Color::GREEN);
    userPath += ":";
    userPath += Color::wrap(abbreviatePath(cwd), Color::BLUE);

    return envError ? EXIT_FAILURE : EXIT_SUCCESS;
}
