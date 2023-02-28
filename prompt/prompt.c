/**
 * @file prompt.c
 * @author Vincent Lin (vinlin24@outlook.com)
 * @brief Output a custom, formatted shell prompt. Written as a performant
 * replacement for my prompt_command and related functions in my .bashrc.
 * @date 2023-02-28
 */

#include <stdio.h>
#include <stdlib.h>

#include "branch_state.h"

int main(void)
{
    char branch_state[MAX_BRANCH_STATE_LENGTH];
    get_branch_state(branch_state, sizeof(branch_state));
    printf("%s\n", branch_state);
    return EXIT_SUCCESS;
}
