/**
 * @file branch_state.hpp
 * @brief Format the Git part of the prompt.
 */

#ifndef BRANCH_STATE_HPP_INCLUDED
#define BRANCH_STATE_HPP_INCLUDED

#include <string>

/* Maximum expected length of a Git branch name, null character included.  */
#define MAX_BRANCH_NAME_LENGTH 100ULL

/* Branch name (null character included) + DETACHED prefix + ANSI color
+ all symbols + ANSI reset.  */
#define MAX_BRANCH_STATE_LENGTH (MAX_BRANCH_NAME_LENGTH + 17 + 5 + 3 + 4 + 1)

/**
 * @brief Parse the output of `git status` to determine the state of the current
 * Git repository, if exists.  Write the current branch name colored and
 * suffixed with symbols mimicking the VS Code GUI notation (* for modified, +
 * for staged, etc.).
 *
 * @param branchState String to write the formatted branch state to.  The branch
 * state string is appended to the string instance.
 * @return int Status code of operation.  EXIT_SUCCESS on normal return.
 * EXIT_FAILURE if failed to run `git status`.  EINVAL if some fatal error
 * during parsing `git status`, or the directory is not a repository.
 */
int getBranchState(std::string &branchState);

#endif // BRANCH_STATE_HPP_INCLUDED
