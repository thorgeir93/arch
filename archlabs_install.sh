USERNAME="test"

# As root
pacman -Syu
pacman -S xorg-server xorg-apps xorg-xinit xterm
pacman -S lightdm
pacman -S lightdm-gtk-greeter lightdm-gtk-gretter-settings

user_run () {
    su -c "$1" $USERNAME
}
# As user
user_run "mkdir -p ~/.config/qtile" 
user_run "cp /usr/share/doc/qtile/default_config.py ~/.config/qtile"

# As root
pacman -Syu
pacman -S sudo

# Manual stuff
# vi /etc/sudoers
# Remove comment from %wheel ALL=(ALL) ALL

 

