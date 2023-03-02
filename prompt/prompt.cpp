/**
 * @file prompt.cpp
 * @author Vincent Lin (vinlin24@outlook.com)
 * @brief TODO.
 * @date 2023-03-01
 */

#include <cstdlib>
#include <iostream>
#include <string>

#include "branch_state.hpp"
#include "venv_state.hpp"

int main(void)
{
    std::string branchState;
    getBranchState(branchState);
    std::cout << branchState << std::endl; // TEMP.

    std::string venvState;
    getVenvState(venvState);
    std::cout << venvState << std::endl; // TEMP.

    return EXIT_SUCCESS;
}
