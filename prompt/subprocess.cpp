/**
 * @file subprocess.cpp
 */

#include <system_error>

#include "subprocess.hpp"

#if defined(WIN32) || defined(_WIN32) || defined(__WIN32) && !defined(__CYGWIN__)
#define POPEN _popen
#define PCLOSE _pclose
#else
#define POPEN popen
#define PCLOSE pclose
#endif

Subprocess::Subprocess(char const *command)
{
    this->pipe = POPEN(command, "r");
    if (this->pipe == nullptr)
        throw std::runtime_error("popen() failed!");

    char buffer[128];
    while (fgets(buffer, sizeof(buffer), this->pipe) != nullptr)
        this->output += buffer;
}

Subprocess::Subprocess(std::string const &command)
    : Subprocess(command.c_str()) {}

Subprocess::~Subprocess()
{
    PCLOSE(this->pipe);
}
