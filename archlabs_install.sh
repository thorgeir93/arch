#!/bin/bash
# On a fresh archlabs instance run as root:
# $ bash archlabs_install.sh
USERNAME="test"

#
# HELP FUNCTIONS
#
user_run () {
    su -c "$1" $USERNAME
}
pacman_update () {
    pacman -Syu --noconfirm
}

pacman_install () {
    pacman -S --noconfirm ${@}
}


#
# INSTALLATION COMMANDS
#

install_x () {
    pacman_update
    pacman_install xorg-server xorg-apps xorg-xinit st
}

install_login_manager () {
    pacman_update
    pacman_install lightdm
    pacman_install lightdm-gtk-greeter lightdm-gtk-greeter-settings

    systemctl enable lightdm
}

install_qtile () {
    pacman_update
    pacman_install qtile
}

install_utils () {
    pacman_update
    pacman_install sudo
}

#
# CONFIGURATION
#
config_qtile () {
    user_run "mkdir -p ~/.config/qtile" 
    user_run "cp /usr/share/doc/qtile/default_config.py ~/.config/qtile"

    # Make the alt key be the super key.
    user_run "sed -i 's/mod \= \"mod4\"/mod \= \"mod1\"/' ~/.config/qtile/config.py"
}

set_keyboard () {
    # Set keyboard layout in Arch linux
    ls /usr/share/kbd/keymaps/**/*.gz
    loadkeys is-latin1-us
}

#
# RECIPE
#
begin () {
    
    install_x
    install_login_manager

    install_qtile
    config_qtile

    install_utils

    echo "Your turn:"
    echo "$ vi /etc/sudoers"
    echo "Remove comment from %wheel ALL=(ALL) ALL"

    echo "FINISH!"
}

begin
