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
#include "user_path.hpp"
#include "venv_state.hpp"

int main(void)
{
    std::string venvState;
    getVenvState(venvState);
    if (!venvState.empty())
        venvState += " ";

    std::string userPath;
    getUserPath(userPath);
    if (!userPath.empty())
        userPath += " ";

    std::string branchState;
    getBranchState(branchState);

    /* Line 1: Information to display.  */
    std::cout << venvState << userPath << branchState << std::endl;

    /* Line 2: Actual line to write on.  */
    std::cout << "$ ";

    return EXIT_SUCCESS;
}
