#!/usr/bin/env bash

repo_dir="${HOME}/repos/startup-config"

# Create symlinks for dotfiles.
ln -sf "${repo_dir}/.bashrc" "${HOME}/.bashrc"
ln -sf "${repo_dir}/.bash_profile" "${HOME}/.bash_profile"
ln -sf "${repo_dir}/.gitconfig" "${HOME}/.gitconfig"
ln -sf "${repo_dir}/.gitfuncs" "${HOME}/.gitfuncs"

# Update our custom bin directory for custom scripts/binaries.
mkdir -p "${HOME}/bin"
make all
cp bin/* "${HOME}/bin"
make clean
