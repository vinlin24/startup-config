# .bashrc
# Startup script for Git Bash shell.

# NOTE: For some reason, to reference my home directory (C:\Users\vinlin), ~
# works in some places but not in others, and I have no idea why.

# Git still runs /C/Program Files/Git/etc/profile.d/aliases.sh even though I
# have my own .bashrc set up, I don't know why
unalias -a

# Default editor <3
export EDITOR=code

# ANSI color codes
export END=$(tput sgr0)
export BLACK=$(tput setaf 0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)
export MAGENTA=$(tput setaf 5)
export CYAN=$(tput setaf 6)
export WHITE=$(tput setaf 7)
export BOLD=$(tput bold)
export DIM=$(tput dim)

# Meta aliases
alias rc='code ~/.bashrc'
alias refresh='source ~/.bashrc'

# Convenience aliases
alias activate='source .venv/Scripts/activate'
alias la="ls -A"
alias ll="ls -Al"

# Partials of existing commands
alias grep="grep --color=auto"
alias egrep="grep --color=auto -E"
alias diff="diff --color=auto"
alias udiff="diff --color=auto -u"

# Connect to UCLA Engineering lnxsrv NUM, default 15.
function seas() {
    local SERVER_NUM=15 # ol' reliable
    if [ ! -z "$1" ]; then
        SERVER_NUM="$1"
    fi
    ssh "classvin@lnxsrv${SERVER_NUM}.seas.ucla.edu"
}

# Shorthand for compiling and running Verilog code
function verilog() {
    # Default, like in EDA playground
    local FILENAMES="'design.sv' 'testbench.sv'"

    # If any arguments were provided at all, use those as filenames instead
    if [ $# -ne 0 ]; then
        FILENAMES=""
        # This automatically loops over all items in $@
        for i; do
            FILENAMES="${FILENAMES}${i@Q} "
        done
        # Remove trailing whitespace, I don't know why this works
        # https://stackoverflow.com/a/3352015/14226122
        FILENAMES="${FILENAMES%"${FILENAMES##*[![:space:]]}"}"
    fi

    # Using same compiler options as in EDA playground
    local COMMAND="iverilog -Wall -g2012 ${FILENAMES} && vvp a.out"

    # Dimmed echo to display to caller what was really run under the hood
    echo -e "\x1b[2mverilog: ${COMMAND}\x1b[22m"

    # Evaluate the command and echo success/failure just for convenience
    if eval " ${COMMAND}"; then
        echo "$(tput setaf 2)Exited without error$(tput sgr0)"
        return 0
    else
        echo "$(tput setaf 1)Exited with error$(tput sgr0)"
        return 1
    fi
}

###################################################################
####################    Custom Shell Prompt    ####################
###################################################################

# Echo the state of the current Git branch, if applicable. The format of the
# state imitates that of VS Code's branch indicator in the bottom left of the
# GUI, with markers like *, +, and ! to denote specific status(es) of the
# working branch.
function get_branch_state() {

    # Git doesn't have an official API for getting the status of the current
    # branch, but I can use certain plumbing commands to check for states.

    # Not a repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    # The color priority is: GREEN (clean) > RED (conflict) > MAGENTA (staged) >
    # YELLOW (modified) > BLACK (unknown). These states can occur independently
    # of each other, so check in reverse order so that the highest takes
    # precedence. An exception is checking for a clean tree first because if a
    # tree is clean, we don't need to check anything else.

    local color="$BLACK"
    local marks=""

    # CLEAN: working tree is clean
    if git diff-index --quiet HEAD; then
        color="$GREEN"
    else
        # MODIFIED: unstaged changes
        if [ -n "$(git diff-files)" ]; then
            color="$YELLOW"
            marks+="*"
        fi
        # STAGED: staged changes
        if ! git diff --staged --quiet; then
            color="$MAGENTA"
            marks+="+"
        fi
        # CONFLICT: merge conflicts
        if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
            color="$RED"
            marks+="!"
        fi
    fi

    # Get the branch name if possible
    local branch=$(git rev-parse --abbrev-ref HEAD)
    local detached=""

    # If detached HEAD mode, use the tag if applicable, else abbreviated hash
    if [ "$branch" = "HEAD" ]; then
        detached="DETACHED:"
        branch=$(git describe --tags --exact-match 2>/dev/null)
        if [ -z "$branch" ]; then
            branch=$(git rev-parse --short HEAD)
        fi
    fi

    # Final colored output
    echo "${color}(${DIM}${detached}${END}${color}${branch}${marks})${END}"
}

function prompt_command() {
    # Save exit code of last command first thing so it's not overwritten
    local exit_code=$?
    local error_code=""
    if [ $exit_code -ne 0 ]; then
        error_code=" ↪ ${RED}${exit_code}${END}"
    fi

    local venv_state=""
    local elbow="${GREEN}\$${END}"

    # Check if we're within an activated venv
    if [ "$VIRTUAL_ENV" ]; then
        local venv=$(basename $VIRTUAL_ENV)
        local origin=$(basename $(dirname $VIRTUAL_ENV))
        local version=$(python --version | awk '{print $2}')
        venv_state="${CYAN}(${venv}[${version}]@${origin})${END} "
        elbow="${CYAN}\$${END}"
    fi

    # Information to display
    local shellInfo="${MAGENTA}${MSYSTEM}${END}"
    local userPath="${GREEN}\u@\h${END} ${shellInfo} ${BLUE}\w${END}"
    local branch_state=$(get_branch_state)
    local prompt="${venv_state}${userPath} ${branch_state}${error_code}"
    # Actual line to write on below the info line
    prompt="${prompt}\n${elbow} "

    export PS1=$prompt
}

export PROMPT_COMMAND=prompt_command

###################################################################

# Run git pull on this repository. IMPORTANT: () instead of {} wrapping function
# definition means that this function is run in a SUBSHELL. This is to prevent
# set -e from quitting the entire shell.
function sync_config() (
    # Symlink is at this path
    local SYMLINK_PATH="${BASH_SOURCE[0]}"
    local THIS_SCRIPT_PATH=$(realpath "$SYMLINK_PATH")
    local THIS_REPO_PATH=$(dirname "$THIS_SCRIPT_PATH")
    cd $THIS_REPO_PATH
    if [ $? -ne 0 ]; then
        echo >&2 "Failed to change directory to ${THIS_REPO_PATH}."
        return 1
    fi

    local BRANCH_TO_PULL="HEAD"
    # Optionally check out to another branch if specified
    if [ $# -ne 0 ]; then
        BRANCH_TO_PULL="$1"
    fi

    set -e
    git checkout "$BRANCH_TO_PULL"
    git pull origin "$BRANCH_TO_PULL"
)
