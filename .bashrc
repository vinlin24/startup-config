#!/usr/bin/env bash
# Startup script for Git Bash shell.

# NOTE: For some reason, to reference my home directory (C:\Users\vinlin), ~
# works in some places but not in others, and I have no idea why.

# Git still runs /C/Program Files/Git/etc/profile.d/aliases.sh even though I
# have my own .bashrc set up, I don't know why
unalias -a

# Custom binaries go in ~/bin
export PATH="$HOME/bin:$PATH"

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

# C standard exit codes
export EXIT_SUCCESS=0
export EXIT_FAILURE=1
export EINVAL=22

# Paths relevant to me
export REPOS_DIR="${HOME}/repos"

# Shortcuts since my ucla folders are buried deep inside Documents
export QUARTER="Spring 23" # Change every quarter
export UCLA="${HOME}/Documents/ucla"
export CLASSES="${UCLA}/classes/${QUARTER}"
export UPE="${UCLA}/UPE"

# Meta aliases
alias rc='code ~/.bashrc'
alias refresh='source ~/.bashrc'

# Convenience aliases/partials of existing commands
alias updatepip='python -m pip install --upgrade pip'
alias la="ls -A"
alias ll="ls -Al"
alias grep="grep --color=auto"
alias egrep="grep --color=auto -E"
alias diff="diff --color=auto"
alias udiff="diff --color=auto -u"
alias mime-type="file -b --mime-type"
alias mime-encoding="file -b --mime-encoding"

# Easier way to get a tab at the command line e.g. "$(tab)"
alias tab="echo -en '\\011'"

# Easter egg lol
alias hello=git

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

function pycache() {
    local directory="$1"
    if [ -z "$directory" ]; then
        directory="."
    fi
    find "$directory" -type d -name "__pycache__" -exec rm -rf {} +
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
        if [ "$(pwd)" = "/" ]; then
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
        python -m pip install --upgrade pip
    else
        echo "Decided not to create a virtual environment."
    fi
}

# Repeatedly run the `time` command and average the values.
function avg_time() {
    if [ $# -lt 2 ]; then
        echo >&2 "USAGE: avg_time NUM_TRIALS COMMAND..."
        return 1
    fi

    local num_trials=$1
    # Discard the first (num_trials) argument and take the rest as the command.
    shift
    local argv=("$@")

    local total_real="0"
    local total_user="0"
    local total_sys="0"
    for trial_num in $(seq 1 $num_trials); do
        local output=$({ time -p "$argv" >/dev/null; } 2>&1)
        local real_secs=$(echo "$output" | sed '1q;d' | awk '{print $2}')
        local user_secs=$(echo "$output" | sed '2q;d' | awk '{print $2}')
        local sys_secs=$(echo "$output" | sed '3q;d' | awk '{print $2}')

        total_real=$(awk "BEGIN {printf \"%.3f\", ${total_real}+${real_secs}}")
        total_user=$(awk "BEGIN {printf \"%.3f\", ${total_user}+${user_secs}}")
        total_sys=$(awk "BEGIN {printf \"%.3f\", ${total_sys}+${sys_secs}}")
    done

    local avg_real=$(awk "BEGIN {printf \"%.3f\", ${total_real}/${num_trials}}")
    local avg_user=$(awk "BEGIN {printf \"%.3f\", ${total_user}/${num_trials}}")
    local avg_sys=$(awk "BEGIN {printf \"%.3f\", ${total_sys}/${num_trials}}")

    echo "Average real: ${avg_real}"
    echo "Average user: ${avg_user}"
    echo "Average sys:  ${avg_sys}"
}

# Helper function for workspace().
function _open_workspace() {
    local repo="$1"
    local workspace=$(ls -1 "$repo"*.code-workspace 2>/dev/null | head -n 1)
    if [ "$workspace" ]; then
        echo "Opening by workspace file ${BOLD}${workspace}${END}"
        code "$workspace"
    else
        echo "No workspace file found, opening directory ${BOLD}${repo}${END}"
        code "$repo"
    fi
    return 0
}

function workspace() {
    local repos=()
    readarray -t repos <<<"$(ls -d1 "$REPOS_DIR"/*/)"

    # No name was given: just list out all the repositories.
    local name="$1"
    if [ -z "$name" ]; then
        for ((i = 0; i < ${#repos[@]}; i++)); do
            local trimmed="${repos[$i]#"$REPOS_DIR"}"
            trimmed="${trimmed#/}"
            trimmed="${trimmed%/}"
            echo "$trimmed"
        done
        return 0
    fi

    local matches=()
    readarray -t matches <<<"$(printf -- '%s\n' "${repos[@]}" | grep "$name")"
    # #matches[@] is 1 even if there were no matches because matches still has 1
    # element, the empty string.
    local num_matches=0
    if [ "$matches" ]; then
        num_matches=${#matches[@]}
    fi

    if [ $num_matches -eq 0 ]; then
        echo -n "${YELLOW}No repository found that matches ${BOLD}${name}${END}"
        echo -n "${YELLOW}. Create one? [y/N] ${END}"
        read -r confirmation
        if [[ $confirmation =~ ^[yY].* ]]; then
            local new_repo="$REPOS_DIR"/"$name"
            mkdir "$new_repo"
            echo "Created new directory ${BOLD}${new_repo}${END}"
            code "$new_repo"
        else
            echo "Decided not to create a new workspace."
        fi
        return 0
    fi

    # Non-ambiguous match: directly open the workspace.
    local repo
    if [ $num_matches -eq 1 ]; then
        repo="${matches[0]}"
        _open_workspace "$repo"
        return 0
    fi

    # Ambiguous matches: prompt for choice.
    echo "${YELLOW}Multiple repositories match ${BOLD}${name}${END}"
    for ((i = 0; i < $num_matches; i++)); do
        echo "[${i}] ${matches[$i]}"
    done
    echo -n "${YELLOW}Which to choose? [0-$((num_matches - 1))] ${END}"
    local index
    read -r index

    # Invalid choice if index is non-numeric or not in [0, num_matches).
    if ! echo -n "$index" | grep -qE '^-?[0-9]+$' ||
        [ $index -ge $num_matches ] || [ $index -lt 0 ]; then
        echo >&2 "${RED}Invalid choice ${BOLD}${index}${END}"
        return 1
    fi

    repo="${matches[$index]}"
    _open_workspace "$repo"
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

    test -n "$(git ls-files --others --exclude-standard)"
    has_untracked=$?

    # CLEAN: working tree is clean (including NO untracked files)
    if git diff-index --quiet HEAD && [ $has_untracked -ne 0 ]; then
        color="$GREEN"
    else
        # MODIFIED: unstaged changes OR untracked files
        if [ -n "$(git diff-files)" ] || [ $has_untracked -eq 0 ]; then
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
    local user_path="${GREEN}\u@\h${END} ${shell_info} ${BLUE}\w${END}"

    # Second line (the line I actually write on)
    local elbow="${GREEN}\$${END}"

    # Python venv state
    local venv_state=$(venv_state 2>/dev/null || get_venv_state)
    if [ "$venv_state" ]; then
        venv_state+=" "
        # Make the elbow color match the venv state color
        elbow="${CYAN}\$${END}"
    fi

    # Git branch state: use new speedy C program, but fall back to original
    # script version if it fails for some reason.
    local branch_state=$(branch_state 2>/dev/null || get_branch_state)

    # Final prompt
    local prompt="${venv_state}${user_path} ${branch_state}${error_code}"
    prompt+="\n${elbow} "
    export PS1="$prompt"
}

export PROMPT_DIRTRIM=2
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
