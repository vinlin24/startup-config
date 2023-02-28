/**
 * @file branch_state.h
 * @brief Format the Git part of the prompt.
 */

#ifndef BRANCH_STATE_H_INCLUDED
#define BRANCH_STATE_H_INCLUDED

#include <stdlib.h>

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
 * @param buffer Buffer to write the formatted branch state to.  If an error
 * occurs, the buffer is at least set to the empty string.
 * @param buffer_size Size limit of the buffer as to avoid overflows.  Should
 * not be 0.
 * @return int Status code of operation.  EXIT_SUCCESS on normal return.
 * EXIT_FAILURE if failed to run `git status`.  EINVAL if some fatal error
 * during parsing `git status`, or the directory is not a repository.
 */
int get_branch_state(char *buffer, size_t buffer_size);

#endif // BRANCH_STATE_H_INCLUDED
