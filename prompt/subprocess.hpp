/**
 * @file subprocess.hpp
 */

#include <cstdio>

#include <string>

class Subprocess
{
public:
    Subprocess(char const *command);
    Subprocess(std::string const &command);
    ~Subprocess();

    inline std::string const &getOutput(void) const { return this->output; }

private:
    FILE *pipe;
    std::string output;
};
