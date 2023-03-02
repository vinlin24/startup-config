/**
 * @file venv_state.cpp
 */

#include <cstdlib>

#include <filesystem>
#include <sstream>

#include "color.hpp"
#include "subprocess.hpp"

namespace fs = std::filesystem;

static std::string getPythonVersion(void)
{
    Subprocess python("python --version 2>&1");
    std::string const &output = python.getOutput();

    return "3.10.7"; // TODO.
}

int getVenvState(std::string &venvState)
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
    std::ostringstream oss;
    oss << Color::ansi(Color::CYAN)
        << "(" << venvName.string()
        << "[" << pythonVersion << "]"
        << "@" << originName.string() << ")"
        << Color::ansi(Color::END);

    venvState += oss.str();
    return EXIT_SUCCESS;
}
