# Startup Scripts and Configuration Files


All my shell-related startup scripts and configuration files in one place. With multiple laptops, each with their own WSL, and user accounts for remote servers to worry about, having all these files (finally) backed up and under version control will help me synchronize my many shell environments and take a massive cognitive load off my head.


## Files


* For the **Bourne Again Shell (bash)**:
  * [.bash_profile](.bash_profile): Logon script.
  * [.bashrc](.bashrc): Shell startup script.

* For the **Git** version control system:
  * [.gitconfig](.gitconfig): Configuration file for global settings, most notably my command aliases.
  * [.gitfuncs](.gitfuncs): Script file to `source` from `.gitconfig` for more complicated command aliases.

* For the **Python** interpreter:
  * [.pystartup](.pystartup): Python code to run when the interactive REPL is launched. The original path for this file can be set with the `PYTHONSTARTUP` environment variable.

* For **Windows PowerShell**:
  * [Microsoft.PowerShell_profile.ps1](Microsoft.PowerShell_profile.ps1): Shell startup script.


## Setup


Many startup scripts must be located at a specific path on the filesystem, so in order to get all of them in one place for convenient version control, **symlinks** should be created at their original paths and linked to the files here.

In Windows, this can be done by using the `mklink` command in CMD in **Administrator Mode**:

```cmd
mklink LINK TARGET
```

For my particular case, this repository is located under my home directory, at the expansion of `%USERPROFILE\repos\startup-config`. For example, since `.bashrc` must be at the top-level of the home directory, to set up the symlink I would run:

```cmd
mklink "%USERPROFILE%\.bashrc" "%USERPROFILE%\repos\startup-config\.bashrc"
```

Original paths, where `~` denotes my `%USERPROFILE%`:

* `~/.bash_profile`
* `~/.bashrc`
* `~/.gitconfig`
* `~/.gitfuncs`
* `~/.pystartup`
* `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
