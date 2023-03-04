/**
 * @file venv_state.cpp
 */

#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <optional>
#include <string>

#include "color.h"

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
#define POPEN _popen
#define PCLOSE _pclose
#else
#define POPEN popen
#define PCLOSE pclose
#endif

namespace fs = std::filesystem;

static std::string
runSubprocess(char const *command)
{
    FILE *pipe = POPEN(command, "r");
    if (pipe == nullptr)
        throw std::runtime_error("popen() failed!");

    std::string output;

    char buffer[128];
    while (fgets(buffer, sizeof(buffer), pipe) != nullptr)
        output += buffer;

    if (PCLOSE(pipe) != EXIT_SUCCESS)
        throw std::runtime_error("pclose() failed!");

    return output;
}

static inline std::optional<std::string>
substringAfter(std::string const &string, std::string const &prefix)
{
    std::size_t pos = string.find(prefix);
    if (pos != std::string::npos)
        return string.substr(pos + prefix.size());
    return std::nullopt;
}

static std::string getPythonVersion(void)
{
    std::string output = runSubprocess("python --version 2>&1");

    auto result = substringAfter(output, "Python ");
    if (!result.has_value())
        throw std::runtime_error("Failed to parse `python --version`.");
    std::string &version = result.value();

    /* Strip the trailing newline.  */
    version.pop_back();
    return version;
}

int main(void)
{
    char const *VIRTUAL_ENV = getenv("VIRTUAL_ENV");
    if (VIRTUAL_ENV == nullptr)
        return EXIT_FAILURE;

    /* Example: /home/bob/app/.venv */
    fs::path venvPath(VIRTUAL_ENV);

    /* Example: .venv  */
    fs::path venvName = venvPath.filename();
    /* Example: app  */
    fs::path originName = venvPath.parent_path().filename();

    /* Example: 3.10.7  */
    std::string pythonVersion = getPythonVersion();

    /* Example: (.venv[3.10.7]@app)  */
    std::cout << CYAN
              << "(" << venvName.string()
              << "[" << pythonVersion << "]"
              << "@" << originName.string() << ")"
              << END;

    return EXIT_SUCCESS;
}
