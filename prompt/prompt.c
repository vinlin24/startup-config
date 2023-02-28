#include <stdio.h>
#include <stdlib.h>

#include "branch_state.h"

#define BRANCH_STATE_LENGTH (MAX_BRANCH_LENGTH + 50)

int main(void)
{
    char branch_state[BRANCH_STATE_LENGTH];
    get_branch_state(branch_state, sizeof(branch_state));
    printf("%s\n", branch_state);
    return EXIT_SUCCESS;
}
