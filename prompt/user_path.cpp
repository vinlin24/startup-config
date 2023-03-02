/**
 * @file user_path.cpp
 */

#include <cstdlib>
#include <filesystem>

#include "color.hpp"
#include "user_path.hpp"

namespace fs = std::filesystem;

static std::string abbreviatePath(fs::path const &path)
{
    return "/abbreviated/path/TODO"; // TODO.
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
