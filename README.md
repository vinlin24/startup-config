# Startup Scripts and Configuration Files (dotfiles)

All my shell-related startup scripts and configuration files in one place. With
multiple laptops, each with their own WSL, and user accounts for remote servers
to worry about, having all these files (finally) backed up and under version
control will help me synchronize my many shell environments and take a massive
cognitive load off my head.


## Files

* For the **Bourne Again Shell (bash)**:
  * [.bash_profile](.bash_profile): Logon script.
  * [.bashrc](.bashrc): Shell startup script.

* For the **Git** version control system:
  * [.gitconfig](.gitconfig): Configuration file for global settings, most
    notably my command aliases.
  * [.gitfuncs](.gitfuncs): Script file to `source` from `.gitconfig` for more
    complicated command aliases.

<!-- * For the **Python** interpreter:
  * [.pystartup](.pystartup): Python code to run when the interactive REPL is
    launched. The original path for this file can be set with the
    `PYTHONSTARTUP` environment variable. -->

* ~~For **Windows PowerShell**:~~ *(**deprecated** as I always use Git Bash on
  Windows now)*
  * ~~[Microsoft.PowerShell_profile.ps1](Microsoft.PowerShell_profile.ps1): Shell
    startup script.~~


## Setup

Many startup scripts must be located at a specific path on the filesystem, so in
order to get all of them in one place for convenient version control,
**symlinks** should be created at their original paths and linked to the files
here.


### Not Windows

On non-Windows systems, you should be able to just run:

```sh
./setup.sh
```

This will create symlinks under the `$HOME` directory pointing towards the files
in the local copy of this repository. This also compiles any source code
specified in the [Makefile](Makefile) into [bin/](bin/) and copies its contents
into a special `${HOME}/bin` directory. These are scripts or binaries intended
to be included on one's `$PATH`.

> :warning: This means that [`.bashrc`](.bashrc) or the appropriate startup
> script should make sure `${HOME}/bin` is added to `$PATH`:
>
> ```sh
> export PATH="${HOME}/bin:${PATH}"
> ```


### Windows

In Windows, `ln -s` does not work as expected. Instead, you have to use the
`mklink` command in CMD in **Administrator Mode**:

```cmd
mklink LINK TARGET
```

For my particular case, this repository is located under my home directory, at
the expansion of `%USERPROFILE\repos\startup-config`. For example, since
`.bashrc` must be at the top-level of the home directory, to set up the symlink
I would run:

```cmd
mklink "%USERPROFILE%\.bashrc" "%USERPROFILE%\repos\startup-config\.bashrc"
```

An exception was the PowerShell profile `Microsoft.PowerShell_profile.ps1`.
Apparently, the PowerShell interpreter cannot resolve symlinks, so I simply
replaced the content of the file at `$profile` to source my script in this
repository:

```ps1
<# Delegate startup code to my version-controlled script elsewhere #>
. "${HOME}\repos\startup-config\Microsoft.PowerShell_profile.ps1"
```

Original paths, where `~` denotes my `%USERPROFILE%`:

* `~/.bash_profile`
* `~/.bashrc`
* `~/.gitconfig`
* `~/.gitfuncs`
* `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`

For the standalone scripts or binaries, copy them to our special `bin/`
directory under our home directory.

```sh
mkdir "~/bin"
# Add %USERPROFILE%\bin to the Path user environment variable.
cp bin/binary_name.exe ~/bin
```

Note that you if you're setting up the directory and `PATH` for the first time,
you probably need to restart your computer to see the effect.


## Syncing

[`.bashrc`](.bashrc) defines the `sync_config` function, which you can use to
update the local repository directly from the command line:

```sh
sync_config
```

Note that, at the moment, you will also have to manually run the
[`setup.sh`](setup.sh) script again if there are new symlinks to create or
updated binaries to compile.
