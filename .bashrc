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
alias updatepip='python -m pip install --upgrade pip'
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

function activate() {
    local venv_folder="$1"
    if [ -z "$venv_folder" ]; then
        venv_folder=".venv"
    fi

    local windows_path="${venv_folder}/Scripts/activate"
    local posix_path="${venv_folder}/bin/activate"

    local original_cwd=$(pwd)
    local condition=true
    while $condition; do
        if [ -f "$windows_path" ]; then
            source "$windows_path"
            cd "$original_cwd"
            return 0
        fi
        if [ -f "$posix_path" ]; then
            source "$posix_path"
            cd "$original_cwd"
            return 0
        fi
        if [ $(pwd) = "/" ]; then
            condition=false
        else
            cd ..
        fi
    done

    cd "$original_cwd"
    echo -n "${YELLOW}Could not find a virtual environment directory "
    echo -n "${venv_folder} in current and parent directories. "
    echo -n "Create one? [y/N]${END} "

    read -r confirm
    if [ "$confirm" = "y" ]; then
        echo "Making virtual environment ${venv_folder} in current directory..."
        python -m venv "$venv_folder"
        source "$windows_path" 2>/dev/null || source "$posix_path"
    else
        echo "Decided not to create a virtual environment."
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

    # No commits yet
    if ! git rev-parse HEAD &>/dev/null; then
        echo "${BLACK}(<empty>)${END}"
        return 0
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

# Echo the (colored) part of the prompt describing the state of the currently
# activated Python virtual environment. Output nothing and exit with error if no
# virtual environment is currently activated.
function get_venv_state() {
    if [ "$VIRTUAL_ENV" ]; then
        local venv=$(basename $VIRTUAL_ENV)
        local origin=$(basename $(dirname $VIRTUAL_ENV))
        local version=$(python --version | awk '{print $2}')
        echo "${CYAN}(${venv}[${version}]@${origin})${END} "
        return 0
    fi
    return 1
}

# Output up to the last two (colored) components of the current working
# directory. Also prefix the path with ~ if we're under the home directory. If
# part of the path between the root (/) or home directory (~) was omitted, use
# ... in its place. Some of this code was adapted from ChatGPT.
function get_abbreviated_cwd() {
    local cwd=$(pwd)

    # AT the home directory
    if [ "$cwd" = "$HOME" ]; then
        echo "${BLUE}~${END}"
        return 0
    fi

    local subpath="$cwd"
    local home_prefix=""

    if [[ $cwd = "$HOME"* ]]; then
        subpath=${cwd#"$HOME/"}
        # If we're somewhere under the home directory
        if [ "$subpath" != "$HOME" ]; then
            home_prefix="~/"
        fi
    fi

    # Split the path into an array using '/' as the delimiter
    IFS='/' read -ra subpath_components <<<"$subpath"
    local length=${#subpath_components[@]}

    # For some reason when home_prefix="", the length is one more than expected.
    if [ $length -le 2 ] || [ -z "$home_prefix" ] && [ $length -le 3 ]; then
        # Just echo the entire path
        echo "${BLUE}${home_prefix}${subpath}${END}"
    else
        # Otherwise just the last 2 components, with /.../ abbreviation prefix
        local second_last="${subpath_components[$((length - 2))]}"
        local last="${subpath_components[$((length - 1))]}"
        echo "${BLUE}${home_prefix}.../${second_last}/${last}${END}"
    fi
}

# Redefine the shell prompt. Example prompt (real one would be colored):
# vinlin@Vincent MINGW64 repos/startup-config (main*) ↪ 1
function prompt_command() {
    # Save exit code of last command first thing so it's not overwritten
    local exit_code=$?
    local error_code=""
    if [ $exit_code -ne 0 ]; then
        error_code=" ↪ ${RED}${exit_code}${END}"
    fi

    # Basic information to display
    local shell_info="${MAGENTA}${MSYSTEM}${END}"
    local user_path="${GREEN}\u@\h${END} ${shell_info} $(get_abbreviated_cwd)"

    # Second line (the line I actually write on)
    local elbow="${GREEN}\$${END}"

    # Python venv state
    local venv_state=$(get_venv_state)
    if [ "$venv_state" ]; then
        # Make the elbow color match the venv state color
        elbow="${CYAN}\$${END}"
    fi

    # Git branch state
    local branch_state=$(get_branch_state)

    # Final prompt
    local prompt="${venv_state}${user_path} ${branch_state}${error_code}"
    prompt+="\n${elbow} "
    export PS1="$prompt"
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
