#!/usr/bin/env bash

# Create symlinks for dotfiles.
ln -sf "${HOME}/.bashrc" .bashrc
ln -sf "${HOME}/.bash_profile" .bash_profile
ln -sf "${HOME}/.gitconfig" .gitconfig
ln -sf "${HOME}/.gitfuncs" .gitfuncs

# Update our custom bin directory for custom scripts/binaries.
mkdir "${HOME}/bin"
make all
cp bin/* "${HOME}/bin"
make clean
