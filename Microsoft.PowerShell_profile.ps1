<# ANSI Escape Sequences #>
$ESC = [char]27
$RESET = "$ESC[0m"
$DEFAULT = "$ESC[39m"
# All of these are bolded too
$BLACK = "$ESC[1;30m"
$RED = "$ESC[1;31m"
$GREEN = "$ESC[1;32m"
$YELLOW = "$ESC[1;33m"
$BLUE = "$ESC[1;34m"
$MAGENTA = "$ESC[1;35m"
$CYAN = "$ESC[1;36m"
$WHITE = "$ESC[1;37m"


<# Helper function for prompt #>
function get_branch_state () {
    # Otherwise determine the color and symbols from the status
    # Use the same notation as VS Code in the bottom left corner:
    # '*' for modified, '+' for staged, '*+' for both, '!' for conflict
    $status = (git status) -join "`n" 2> $null

    # git error, probably not a repository
    if ($status -eq "") { return "" }

    # Parse for the other states; color priority:
    # red (conflict) > magenta (staged) > yellow (modified) > green (clean)
    $color = $BLACK
    $marks = ""

    # These can occur independently of each other
    # Check in reverse order of color priority so that highest takes precedence
    if ($status | Select-String "nothing to commit, working tree clean") {
        $color = $GREEN
    }
    if ($status | Select-String "(Changes not staged for commit|Untracked files):") {
        $color = $YELLOW
        $marks += "*"
    }
    if ($status | Select-String "Changes to be committed:") {
        $color = $MAGENTA
        $marks += "+"
    }
    if ($status | Select-String "fix conflicts") {
        $color = $RED
        $marks += "!"
    }

    # Get the branch name if possible
    $match = $status | Select-String "On branch (.+)"
    # Probably in detached HEAD mode, use the tag if applicable, else SHA
    if ($null -eq $match) {
        $match = $status | Select-String "HEAD detached at (.+)"
        # Some other problem, I have no idea
        if ($null -eq $match) { return "" }
        # Use dimmed text because VS Code doesn't support blinking ANSI
        $detachedText = "${ESC}[2mDETACHED${ESC}[22m "
    }
    $branchName = $match.Matches.Groups[1].Value

    return " => ${color}${detachedText}${branchName}${marks}${RESET}"
}

function get_python_state {
    $venv = $env:VIRTUAL_ENV
    if ($venv) {
        $venvName = Split-Path $venv -Leaf
        $venvDir = Split-Path (Split-Path $venv -Parent) -Leaf
        $pythonVersion = (python --version) -replace "Python " , ""
        return "${CYAN}(${venvName}@${venvDir}: ${pythonVersion})${RESET} "
    }
}

<# Override default shell prompt #>
function prompt {
    # Abbreviate the path part to use ~ for home and show at most two
    # layers deep from cwd, while still including ~ or the drive root.
    #
    # For example:
    # ~\...\classes\Fall 22
    # PS>
    #
    # With a venv active and git repository detected:
    # (.venv@counters: 3.10.7) ~\repos\counters => main
    # └─PS>

    $cwd = "$(Get-Location)"
    $root = "$(Get-Item \)"
    if ($cwd -like "${HOME}*") {
        $root = $HOME
    }

    # Case 1: at the root
    if ($cwd -eq $root) {
        $cwdAbbrev = $root
    }

    # Case 2: parent is the root
    elseif ((Split-Path $cwd -Parent) -eq $root) {
        $cwdAbbrev = $cwd
    }

    # Case 3: grandparent is the root
    elseif ((Split-Path (Split-Path $cwd -Parent) -Parent) -eq $root) {
        $cwdAbbrev = $cwd
    }

    # Case 4: there are arbitrary layers between grandparent and root
    else {
        $leaf = Split-Path $cwd -Leaf
        $parent = Split-Path (Split-Path $cwd -Parent) -Leaf
        $parts = @("...", $parent, $leaf)
        $cwdAbbrev = $root
        foreach ($part in $parts) {
            $cwdAbbrev = Join-Path $cwdAbbrev $part
        }
    }

    # Finally replace home part of path with ~
    $cwdAbbrev = $cwdAbbrev -ireplace [regex]::Escape($HOME), "~"

    # Part on the second line
    $prompt = "$([char]9492)$([char]9472)PS> "
    $pythonState = get_python_state
    if ($pythonState) {
        $prompt = "${CYAN}${prompt}${RESET}"
    }
    else {
        $prompt = "${BLUE}${prompt}${RESET}"
    }

    # Final combined prompt
    "${pythonState}${BLUE}${cwdAbbrev}${RESET}$(get_branch_state)`n${prompt}"
}

<# Colorized ls from https://github.com/joonro/Get-ChildItemColor #>
# Only run this in the console and not in the ISE
if (-Not (Test-Path Variable:PSise)) {
    try {
        Import-Module Get-ChildItemColor
    }
    catch {
        Write-Host "Module Get-ChildItemColor could not be loaded." -ForegroundColor Red
    }
    Remove-Item alias:ls -Force
    Set-Alias ll Get-ChildItemColor -option AllScope
    Set-Alias ls Get-ChildItemColorFormatWide -option AllScope
}

<# Define some common commands/aliases reminiscent of bash #>
Remove-Item alias:pwd -Force
function pwd { "$(Get-Location)" }
function ld { Get-ChildItemColor -Directory }
function lf { Get-ChildItemColor -File }

<# Helper function for writing status based on last exit code #>
function Write-CompletionStatus {
    if ($?) {
        Write-Host "Done." -ForegroundColor Green
    }
    else {
        Write-Host "Failed." -ForegroundColor Red
    }
}

<# Helper function for activating the given virtual environment #>
function Open-PythonVenv {
    param (
        [Parameter()]
        [string]$Path
    )
    Write-Host "Activating Python virtual environment $Path..." -NoNewline -ForegroundColor Yellow
    $activatePath = Join-Path -Path $Path -ChildPath "\Scripts\Activate.ps1"
    # Override default prompt so my PS prompt can deal with it
    try { & $activatePath }
    finally { Write-CompletionStatus }
}

<# Activate Python virtual environment, creating it if necessary #>
function activate {
    param (
        [Parameter()]
        [string]$Name = ".venv"
    )

    # Find the virtual environment in current and parent directories
    # Don't bother recursing through child directories because that could
    # take too long depending on where this is run

    # Current directory
    $targetDir = (Get-Location)
    $testPath = Join-Path -Path $targetDir -ChildPath $Name
    # Already exists, just activate it instantly
    if (Test-Path $testPath) {
        Open-PythonVenv -Path $testPath
        return
    }

    # Otherwise search through parent directories
    $targetDir = (Split-Path -Path $targetDir -Parent)

    # The result is the empty string "" when we pop the root
    while ($targetDir) {
        $testPath = Join-Path -Path $targetDir -ChildPath $Name
        # Already exists, ask for confirmation
        if (Test-Path $testPath) {
            Write-Host "Found a virtual environment in a parent directory $targetDir. Is this the one you wanted? (y/N) " -NoNewline -ForegroundColor Yellow
            $confirmation = Read-Host
            if ($confirmation -ne "y") {
                Write-Host "Did not activate $Name." -ForegroundColor Red
                return
            }
            Open-PythonVenv -Path $testPath
            return
        }
        # Pop the current directory off $targetDir
        $targetDir = (Split-Path -Path $targetDir -Parent)
    }

    # Doesn't exist yet, ask if caller wants to create it
    Write-Host "Could not find a virtual environment named $Name in current and parent directories. Would you like to create one here? (y/N) " -NoNewline -ForegroundColor Yellow
    $confirmation = Read-Host
    if ($confirmation -ne "y") {
        Write-Host "Did not create $Name." -ForegroundColor Red
        return
    }

    # Create the virtual environment
    Write-Host "Creating Python virtual environment $Name in current directory..." -NoNewline -ForegroundColor Yellow
    try { python -m venv $Name }
    finally { Write-CompletionStatus }

    # Activate the new virtual environment
    $newVenvPath = Join-Path -Path (Get-Location) -ChildPath $Name
    Open-PythonVenv -Path $newVenvPath
}



<# Get the list of verbs in a separate window #>
function verbs {
    Get-Verb | Out-GridView
}

<# Helper function for Start-ProjectDir #>
function New-ItemAndMsg {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        [Parameter(Mandatory = $true, Position = 1)]
        [bool]$Quiet,
        [Parameter()]
        [switch]$Directory
    )
    if (Test-Path $Path) {
        if (-Not $Quiet) {
            Write-Host "SKIPPED: $Path already exists"
        }
        return
    }
    if ($Directory) {
        New-item -Path $Path -ItemType Directory | Out-Null
    }
    else {
        New-Item -Path $Path | Out-Null
    }
    if (-Not $Quiet) {
        Write-Host "SUCCESS: Created $Path"
    }
}

<# Initialize a barebones project directory #>
function init {
    param (
        # Complexity of template:
        # 0 - no dirs; 1 - src only; 2 - src, test; 3 - src, test, dist, build
        [ValidateRange(0, 3)]
        [Parameter(Position = 0)]
        [int]$Complexity = 0,
        # Create and activate venv and include requirements.txt
        [Parameter()]
        [switch]$PythonTemplate,
        # Suppress creation messages
        [Parameter()]
        [switch]$Quiet
    )

    Write-Host "Creating project directory template..." -ForegroundColor Yellow

    New-ItemAndMsg ".\.gitignore" $Quiet
    New-ItemAndMsg ".\README.md" $Quiet
    if ($Complexity -ge 1) {
        New-ItemAndMsg ".\src" $Quiet -Directory
    }
    if ($Complexity -ge 2) {
        New-ItemAndMsg ".\test" $Quiet -Directory
    }
    if ($Complexity -ge 3) {
        New-ItemAndMsg ".\dist" $Quiet -Directory
        New-ItemAndMsg ".\build" $Quiet -Directory
    }

    if ($PythonTemplate) {
        Write-Host "Opted to include Python essentials..." -ForegroundColor Yellow
        New-ItemAndMsg ".\requirements.txt" $Quiet
        Start-PythonVenv
    }

    Write-Host "Finished creating project directory template." -ForegroundColor Green
}

<# Helper subroutine for Open-CodeWorkspace #>
function _prompt_dir_choice {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]] $RepoList
    )
    $count = 0
    $choiceDescs = @(
        $RepoList | ForEach-Object {
            "&${count}: $($_.Name)"
            $count++
        }
    )
    $choices = [System.Management.Automation.Host.ChoiceDescription[]] $choiceDescs
    # Prompt user input
    $choice = $Host.UI.PromptForChoice(
        "'$Name' matched $count directories",
        "Pick the one you meant to open (or ^C to cancel):",
        $choices,
        0
    )
    # Resolve choice
    return $RepoList[$choice].FullName
}

<# Open one of my repos as a workspace or directory #>
function workspace {
    param (
        [Parameter()]
        [string] $Name,
        [Parameter()]
        [switch] $New
    )

    # Assume the repos folder isn't gonna move lmao
    $reposDirPath = Join-Path $HOME "repos"
    $repos = @(Get-ChildItem $reposDirPath -Directory)
    # Search for folders within these special folders too
    $repos += @(Get-ChildItem "$reposDirPath\dump" -Directory)
    $repos += @(Get-ChildItem "$reposDirPath\clones" -Directory)

    $repoList = @($repos | Where-Object { $_.Name -like "*$Name*" })
    # If no arg was supplied, let the final else catch it
    if ($Name -eq "") {
        $repoList = $null
        $New = $false
    }

    # If such a repository exists:
    if ($repoList.Length -gt 0) {
        # If the name matched multiple results, prompt user to choose
        if ($repoList.Length -gt 1) {
            $repoPath = _prompt_dir_choice $repoList
        }
        else {
            $repopath = $repoList[0].FullName
        }

        $workspaceFile = Get-ChildItem $repoPath "*.code-workspace"
        # I only save one code-workspace per repo but who knows
        if ($workspaceFile -is [array]) {
            $workspaceFile = $workspaceFile[0]
            Start-Process $workspaceFile.PSPath
        }
        # No code-workspace file at all, code.exe the directory:
        elseif ($null -eq $workspaceFile) {
            code $repoPath
        }
        # Invoke the code-workspace file
        else {
            Start-Process $workspaceFile.PSPath
        }
        # Close terminal upon opening VS Code
        exit
    }

    # Otherwise if -New is used, make the repository:
    elseif ($New) {
        $newRepoPath = Join-Path $reposDirPath $Name
        # git init <directory> makes the directory automatically
        # "-b main" to specify starting branch as "main" instead of "master"
        git init -b main $newRepoPath
        code $newRepoPath
        # Close terminal upon opening VS Code
        exit
    }

    # Otherwise list the names of existing repos:
    else {
        Write-Host "No repository found in $reposDirPath with a name like '$Name'." -ForegroundColor Red
        Write-Host "The full list of directories at this location is:" -ForegroundColor Yellow
        foreach ($repo in $repos) {
            # If the repo is in the special directories, skip them
            # Since they'll be handled below
            $dirName = $repo.Parent.Name
            if ($dirName -eq "clones" -or $dirName -eq "dump") {
                continue
            }
            Write-Host $repo.Name
            # List the subdirectories of these special directories
            if ($repo.Name -eq "clones" -or $repo.Name -eq "dump") {
                Get-ChildItem $repo.FullName -Directory | ForEach-Object {
                    Write-Host "  $($_.Name)"
                }
            }
        }
    }
}

function repos {
    Invoke-Item "$env:USERPROFILE\repos"
}

<# Open this file's repository in VS Code #>
function profile {
    code (Split-Path $profile -Parent)
    exit
}

<# Update pip to latest version #>
function updatepip {
    python -m pip install --upgrade pip
}

<# Remove all __pycache__ directories and contents #>
function pycache {
    Get-ChildItem . __pycache__ -Directory -Recurse | Remove-Item -Recurse
}

<# Reinstall the virtual environment in current directory #>
function resetvenv {
    param (
        [Parameter()]
        [string] $Name = ".venv"
    )

    # Validate path
    if (!(Test-Path $Name)) {
        Write-Host "Could not find a file named $Name, aborted." -ForegroundColor Red
        return
    }

    # Try to deactivate, then delete
    try { deactivate } catch {}
    Remove-Item $Name -Recurse
    Write-Host "Removed $Name" -ForegroundColor Yellow

    # Recreate venv
    Write-Host "Creating new virtual environment $Name..." -NoNewline -ForegroundColor Yellow
    python -m venv $Name
    Write-Host "Done." -ForegroundColor Green

    # Activate venv
    & "$Name\Scripts\Activate.ps1"

    # Update pip
    Update-PipVersion

    # Reinstall dependencies, if found
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
        Write-Host "Installed dependencies from requirements.txt." -ForegroundColor Yellow
    }
    else {
        Write-Host "WARNING: Could not find a requirements.txt in current directory." -ForegroundColor Yellow
    }
}

<# Shortcut for logging into engineering server #>
function seas {
    ssh "classvin@lnxsrv15.seas.ucla.edu"
}

<# Start command line Emacs #>
function emacs {
    param (
        [Parameter()]
        [string[]] $EmacsArgs
    )
    & "C:\Program Files\Emacs\emacs-28.2\bin\emacs.exe" -nw $EmacsArgs
}

<# Open with Sublime Text 3 #>
function text {
    param (
        [Parameter()]
        [string[]] $SublimeArgs
    )
    & "C:\Program Files\Sublime Text 3\sublime_text.exe" $SublimeArgs
}

<# Shortcut for reloading this script in current shell #>
function refresh { . $profile }

<# Define some common commands/aliases reminiscent of bash #>
Remove-Item alias:pwd -Force
function pwd { "$(Get-Location)" }
function ld { Get-ChildItemColor -Directory }
function lf { Get-ChildItemColor -File }
Set-Alias -Name "grep" -Value "Select-String"
Set-Alias -Name "touch" -Value "New-Item"
function head {
    param (
        [Parameter()]
        [string] $FilePath,
        [Parameter()]
        [int] $n
    )
    if ($n -lt 0) { $n = 0 }
    Get-Content -Path $FilePath | Select-Object -First $n
}

function tail {
    param (
        [Parameter()]
        [string] $FilePath,
        [Parameter()]
        [int] $n
    )
    if ($n -lt 0) { $n = 0 }
    Get-Content -Path $FilePath | Select-Object -Last $n
}

<# Set permanent user environment variables (requires shell restart) #>
function export {
    param (
        [Parameter()]
        [string] $Expression
    )

    # 'export' alone should list all the environment variables
    if ($Expression -eq "") {
        foreach ($entry in (Get-ChildItem "env:")) {
            Write-Host "$($entry.Name)=`"$($entry.Value)`""
        }
        return
    }

    # Parse 'key=value' pair
    $pair = $Expression -split "=", 2, "SimpleMatch"
    # Ignore, don't give error
    if ($pair.Length -lt 2) {
        Write-Host "Exported nothing. Use key=value syntax." -ForegroundColor Red
        return
    }
    $key = $pair[0]
    $value = $pair[1]
    # Strip quotes off value
    $value = $value.Trim("`"", "'")
    [System.Environment]::SetEnvironmentVariable($key, $value, "User")
    Write-Host "Set ${GREEN}${key}${RESET}=${CYAN}${value}${RESET}"
}

<# Shortcut for getting source path of an executable #>
function which {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Command,
        [Parameter()]
        [switch] $Open
    )
    $source = (Get-Command $Command).Source
    if ($Open) {
        if ($source -and (Test-Path $source)) {
            Invoke-Item (Split-Path $source -Parent)
        }
        else {
            Write-Host "Cannot open directory of '$source'." -ForegroundColor Red
        }
    }
    else {
        return $source
    }
}

<# Getting tired of writing out Split-Path #>
function dirname {
    Split-Path -Parent "$($Args[0])"
}
function basename {
    Split-Path -Leaf "$($Args[0])"
}

<# Use Git bash, not the bash built into System32. #>
function bash {
    & 'C:\Program Files\Git\bin\bash.exe'
}

<# Current convenience cd shortcut #>
function ucla { Set-Location "${HOME}\Documents\ucla\classes\Winter 23\" }

<# No welcome text please #>
Clear-Host
