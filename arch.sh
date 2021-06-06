#!/bin/bash
# Date..: Sun Jun  6 12:40:52 UTC 2021
# ISO V.: 2021.06.01
# Author: Thorgeir Sigurdsson
# Credit: https://wiki.archlinux.org/title/Installation_guide
# Usage.: bash arch_setup.sh
#
# Tested in Virtualbox with EFI enabled in VM settings.
#

set -o xtrace

USERNAME="test"

user_run () {
    su -c "$1" $USERNAME
}


set_base_settings () {
    ###################
    # BASIC SETTINGS  |
    ###################
    timedatectl set-ntp true
    
    # Find keymap
    # ls /usr/share/kbd/keymaps/**/*.map.gz | grep -i is
    
    # Set keymap
    loadkeys is-latin1
}



init_mnt_filesystem () {
    ####################
    # DISK PARTITIONS  |
    ####################
    #
    # Help guides:
    #    * EFI partition - https://wiki.archlinux.org/index.php/EFI_system_partition
    #
    # Credit: https://wiki.archlinux.org/title/Partitioning#Example_layouts
    # ```
    # Mount point on  Partition	Partition type	        Suggested size
    # /boot or /efi1  /dev/sda1	EFI system partition	At least 260 MiB
    # [SWAP]	      /dev/sda2	Linux swap		        More than 512 MiB
    # /	              /dev/sda3	Linux x86-64 root (/)	Remainder of the device
    # ```
    lsblk -p
    # then find relevant disk partition and run:
    # $ cfdisk /dev/sda

    ######################
    # DEFINE FILESYSTEMS
    ######################
    # EFI partition
    mkfs.fat -F32 /dev/sda1

    # Swap partition
    mkswap /dev/sda2
    swapon /dev/sda2

    # Linux Filesystem
    mkfs.ext4 /dev/sda3
   
    #####################
    # MOUNT AND INSTALL 
    #####################
    # Mount on live live image
    mount /dev/sda3 /mnt

    # Install base system for Arch.
    pacstrap /mnt base linux linux-firmware vim
   
    # Generate filesystem table.
    genfstab -U /mnt >> /mnt/etc/fstab

    #mkdir /mnt/efi
    #mount /dev/sda1 /mnt/efi

    echo "Change to new ISO"
    echo "arch-chroot /mnt"
    exit 1
}

install_arch () {
    ln -sf /usr/share/zoneinfo/Iceland /etc/localtime
    hwclock --systohc
    
    # Edit
    vim +177 /etc/locale.gen
    # uncomment: en_US.UTF-8 UTF-8
    #### uncomment: is_IS.UTF-8 UTF-8
    
    echo "LANG=en_US.UTF-8" >> /etc/locale.gen
    
    # Use localectl list-keymaps | grep is
    echo "KEYMAP=is-latin1" >> /etc/locale.gen
    echo "MEGAS" >> /etc/hostname
    
    echo "127.0.0.1      localhost" >> /etc/hosts
    echo "::1            localhost" >> /etc/hosts
    echo "127.0.1.1	     MEGAS.localdomain	MEGAS" >> /etc/hosts
    
    # Set the root password.
    passwd 
    
    #
    # INSTALL GRUB
    #
    pacman -S grub efibootmgr
    mkdir /boot/efi
    munt /dev/sda1 /boot/efi
    lsblk # to check if everything is mounted correctly
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --removable
    grub-mkconfig -o /boot/grub/grub.cfg
    
    exit 0
}

install_finish () {
    umount -R /mnt
    poweroff
    # Then boot up in existing OS
}

install_desktop () {
    ################
    # Window manager
    ################
    
    # As root
    pacman -Syu
    pacman -S xorg-server xorg-apps xorg-xinit xterm
    pacman -S lightdm
    pacman -S lightdm-gtk-greeter lightdm-gtk-gretter-settings
    
    # As user
    user_run "mkdir -p ~/.config/qtile" 
    user_run "cp /usr/share/doc/qtile/default_config.py ~/.config/qtile"
    
    # As root
    pacman -Syu
    pacman -S sudo
    
    # Manual stuff
    # vi /etc/sudoers
    # Remove comment from %wheel ALL=(ALL) ALL
}
    
main () {
    # Inside Arch ISO installer.
    set_base_settings
    init_mnt_filesystem

    # Inside /mnt Arch.
    install_arch


    # Inside Arch ISO installer.
    install_finish

    # After reboot.
    install_desktop
}

main