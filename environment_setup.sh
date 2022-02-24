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

ssh_public_key () {
    #echo "Before continue, add your ssh keys (private/public) to ~/.ssh"
    #read -p "Press enter to continue"

    if [ ! -f ~/.ssh/*.pub ]; then
        echo "Missing ssh keys (private/public)"
        exit 0
    fi
}

git_init () {
    sudo pacman -S git
    mkdir -p $GITPATH/$USERNAME/
}

git_get () {
    git_repo_name=${1}; shift
    pushd $GITPATH/$USERNAME/
    git clone git@github.com:thorgeir93/${git_repo_name}.git
    popd
}

setup_qtile () {
    mkdir -p ~/.config/qtile
    pushd $GITPATH/$USERNAME/configs
    ln -s qtile_config.py ~/.config/qtile/config.py
    popd
}

setup_dotfiles () {
    ln --symbolic $GITPATH/$USERNAME/dotfiles/.bashrc        ~/.bashrc
    ln --symbolic $GITPATH/$USERNAME/dotfiles/.vimrc         ~/.vimrc
    ln --symbolic $GITPATH/$USERNAME/dotfiles/.Xdefaults     ~/.Xdefaults
    ln --symbolic $GITPATH/$USERNAME/dotfiles/.aliases       ~/.aliases
}

main () {
    sudo pacman -S openssh

    ssh_public_key
    git_init

    git_get "wallpapers"
    git_get "dotfiles"
    git_get "configs"

    # TODO install vim pathogen

    setup_dotfiles
    setup_qtile
}

main
