#!/bin/bash
# Date..: Tue Jun  8 21:49:38 UTC 2021
# Author: Thorgeir Sigurdsson
# Usage.: bash environment_setup.sh
#
# Attention:
#   * This script will delete current configs.
#   * This script assumes that the current configs are default ones.
#   * This script will replace the default configs with customade configs from github.
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
    symbolic_link $GITPATH/$USERNAME/configs/qtile_config.py ~/.config/qtile/config.py
}

symbolic_link () {
    filepath_source=$1; shift
    filepath_dest=$1; shift

    # Delete default file and replace it with custom file.
    if [ -f $filepath_dest ]; then
        echo "$filepath_dest already exists."
	    rm $filepath_dest
    fi

    ln --symbolic $filepath_source $filepath_dest
}

setup_dotfiles () {
    symbolic_link $GITPATH/$USERNAME/dotfiles/.bashrc        ~/.bashrc
    symbolic_link $GITPATH/$USERNAME/dotfiles/.vimrc         ~/.vimrc
    symbolic_link $GITPATH/$USERNAME/dotfiles/.Xdefaults     ~/.Xdefaults
    symbolic_link $GITPATH/$USERNAME/dotfiles/.aliases       ~/.aliases
}

setup_timesync () {
    sudo pacman -Syu ntp
    sudo systemctl enable ntpd.service
    sudo systemctl start ntpd.service
    echo "Might need to run this command to update the sync fully:"
    echo "$ timedatectl set-ntp true"
    echo "Try to run just "timedatectl" to see if RTC time is correct."
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
    setup_timesync
}

main
