#!/bin/bash
# Date..: Tue Jun  8 21:49:38 UTC 2021
# Author: Thorgeir Sigurdsson
# Usage.: bash environment_setup.sh
#
# Mostly getting configs from git.
#

set -o xtrace  # Print every command out to stdout.
set -o errexit # Exit immediately if a command exits with non-zero status.

GITPATH=~/git/hub
USERNAME=thorgeir

git_init () {
    pacman -S git
    mkdir -p $GITPATH/$USERNAME/
}

get_dotfiles() {
    pushd $GITPATH/$USERNAME/
    git clone https://github.com/thorgeir93/dotfiles.git
    popd
}

get_wallpaper() {
    pushd $GITPATH/$USERNAME/
    git clone git@github.com:thorgeir93/wallpapers.git
    popd
}

get_configs() {
    pushd $GITPATH/$USERNAME/
    git clone git@github.com:thorgeir93/configs.git
    popd
}

setup_qtile () {
    mkdir -p ~/.config/qtile
    pushd $GITPATH/$USERNAME/configs
    ln -s qtile_config.py ~/.config/qtile/config.py
    popd
}

setup_dotfiles () {
    ln --symbolic ~/$GITPAH/$USERNAME/dotfiles/.bashrc        ~/.bashrc
    ln --symbolic ~/$GITPAH/$USERNAME/dotfiles/.vimrc         ~/.vimrc
    ln --symbolic ~/$GITPAH/$USERNAME/dotfiles/.Xdefaults     ~/.Xdefaults
    ln --symbolic ~/$GITPAH/$USERNAME/dotfiles/.aliases       ~/.aliases
}

main () {
    git_init

    get_dotfiles
    get_configs

    setup_dotfiles
    setup_qtile
}
