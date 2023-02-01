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

# ---------- below paraphrased from my WSL 12/12/2022 ---------- #

function get_branch_state() {
    local status="$(git status 2>/dev/null)"

    # git error, probably not a repository
    if [ "$status" = "" ]; then
        echo ""
        return 1
    fi

    # Parse for the other states; color priority: red (conflict) > magenta
    # (staged) > yellow (modified) > green (clean)
    local color=$BLACK
    local marks=""

    # These can occur independently of each other Check in reverse order of
    # color priority so that highest takes precedence
    if grep -q "nothing to commit, working tree clean" <<<$status; then
        color=$GREEN
    fi
    if grep -qE "(Changes not staged for commit|Untracked files):" <<<$status; then
        color=$YELLOW
        marks="${marks}*"
    fi
    if grep -q "Changes to be committed:" <<<$status; then
        color=$MAGENTA
        marks="${marks}+"
    fi
    if grep -q "fix conflicts" <<<$status; then
        color=$RED
        marks="${marks}!"
    fi

    # Get the branch name if possible
    local branchName=$(echo "$status" | grep 'On branch' | sed 's/On branch //')
    local detachedText=""
    # Probably in detached HEAD mode, use the tag if applicable
    if [ "$branchName" = "" ]; then
        branchName=$(echo "$status" | grep 'HEAD detached at' | sed 's/HEAD detached at //')
        # Use underline instead of blinking bc VS code doesn't support blinking
        detachedText="$(tput smul)DETACHED$(tput rmul) "
        # Some other problem, I have no idea
        if [ "$branchName" = "" ]; then
            echo ""
            return 1
        fi
    fi

    echo " ${color}(${detachedText}${branchName}${marks})${END}"
}

function prompt_command() {
    local venvState=""
    local elbow="${GREEN}\$${END}"

    # Check if we're within an activated venv
    if [ "$VIRTUAL_ENV" ]; then
        local venv=$(basename $VIRTUAL_ENV)
        local origin=$(basename $(dirname $VIRTUAL_ENV))
        local version=$(python --version | awk '{print $2}')
        venvState="${CYAN}(${venv}[${version}]@${origin})${END} "
        elbow="${CYAN}\$${END}"
    fi

    # Information to display
    local shellInfo="${MAGENTA}${MSYSTEM}${END}"
    local userPath="${GREEN}\u@\h${END} ${shellInfo} ${BLUE}\w${END}"
    local prompt="${venvState}${userPath}$(get_branch_state)"
    # Actual line to write on below the info line
    prompt="${prompt}\n${elbow} "

    export PS1=$prompt
}

export PROMPT_COMMAND=prompt_command

# ---------- above paraphrased from my WSL 12/12/2022 ---------- #

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
