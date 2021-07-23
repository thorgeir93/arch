#!/bin/bash
# Date..: Sun Jun  6 12:40:52 UTC 2021
# ISO V.: 2021.06.01
# Author: Thorgeir Sigurdsson
# Credit: https://wiki.archlinux.org/title/Installation_guide
# Usage.: source arch.sh
#
# Tested in Virtualbox with EFI enabled in VM settings.
#
# First steps:
#   $ loadkeys is-latin1
#   $ curl https://raw.githubusercontent.com/thorgeir93/arch/main/arch.sh > arch.sh
#   $ source arch.sh

# set -o xtrace

USERNAME="thorgeir"
SETUP_SCRIPT_URL="https://raw.githubusercontent.com/thorgeir93/arch/main/arch.sh"

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
    
    # Uncomment: en_US.UTF-8 UTF-8
    vim +177 /etc/locale.gen
    locale-gen
    
    #echo "LANG=en_US.UTF-8" >> /etc/locale.gen
    
    # Use localectl list-keymaps | grep is
    #echo "KEYMAP=is-latin1" >> /etc/locale.gen

    echo "MEGAS" >> /etc/hostname
    
    echo "127.0.0.1    localhost" >> /etc/hosts
    echo "::1          localhost" >> /etc/hosts
    echo "127.0.1.1    MEGAS.localdomain    MEGAS" >> /etc/hosts
    
    echo "Set root password ..."
    passwd 

    echo "Set $USERNAME password ..."
    useradd -m $USERNAME
    passwd $USERNAME
    usermod -aG wheel,audio,video,optical,storage $USERNAME

    pacman -S sudo

    # Uncomment "%wheel ALL=(ALL) ALL"
    visudo
    
    #
    # INSTALL GRUB
    #
    pacman -S grub efibootmgr dosfstools os-prober mtools

    mkdir /boot/EFI
    mount /dev/sda1 /boot/EFI

    lsblk -p # to check if everything is mounted correctly

    #grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/EFI --removable
    grub-install --target=x86_64-efi --bootloader-id=grup_uefi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg

    # Enable network
    pacman -S networkmanager
    systemctl enable NetworkManager

    # 
    user_run "curl -L $SETUP_SCRIPT_URL > /home/$USERNAME/archsetup.sh"
    user_run "localectl set-keymap --no-convert is-latin1"

    echo "umount -R /mnt"
    echo "poweroff"
}

install_display_manager () {
    pacman -S lightdm
    pacman -S lightdm-gtk-greeter lightdm-gtk-greeter-settings
    systemctl enable lightdm
}

install_window_manager () {
    sudo pacman -S qtile
    mkdir -p ~/.config/qtile
    cp /usr/share/doc/qtile/default_config.py ~/.config/qtile

    # TODO change mod to mod1
    # Maybe copy my config from github!
}

install_desktop () {
    # 
    # As $USERNAME
    # 

    sudo pacman -Syu
    #pacman -S xorg xorg-server xorg-apps xorg-xinit xterm
    sudo pacman -S xorg xorg-xinit

    # Application browser.
    sudo pacman -S dmenu

    # Wallpaper background process.
    sudo pacman -S nitrogen

    # Compositor to make things transparent.
    sudo pacman -S picom

    # Terminal
    sudo pacman -S alacritty

    install_window_manager

    # To build packages from aur Arch
    # $ pacman -S base-devel

    cp /etc/X11/xinit/xinitrc ~/.xinitrc
    echo "nitrogen --restore &" >> ~/.xinitrc
    echo "picom &" >> ~/.xinitrc
    echo "exec qtile" >> ~/.xinitrc

    # Remove default execution at the bottom.
    vim ~/.xinitrc


    localectl set-keymap --no-convert is-latin1

    # Trying to set keyboard layout.
    setxkbmap is # Works
    loadkeys is-latin1 # Throws error:
    #   couldn't get a file descriptor referring to the console

    #install_display_manager   

    # If not right keymap run
    # See: https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration#Persistent_configuration
    # $ user_run "localectl set-keymap --no-convert is-latin1"
}

    
main () {

    # STEP 1
    # Inside Arch ISO installer.
    set_base_settings

    # STEP 2
    ## RUN FIRST CFDISK!
    #init_mnt_filesystem

    # STEP 3
    ## Inside /mnt Arch.
    #install_arch

    # STEP 4
    ## Back to Arch ISO installer.
    # $ "umount -R /mnt"
    # $ "poweroff"

    # Unplug the Arch ISO installer.
    # Then boot up in existing OS

    # STEP 5
    ## After reboot.
    # As regular user.
    #install_desktop

    # STEP 6
    # Configs
    # As regular user.
    #my_environment
}

print_partition_documentation () {
  echo "Help guides:"
  echo "   * EFI partition - https://wiki.archlinux.org/index.php/EFI_system_partition"
  echo ""
  echo "Credit: https://wiki.archlinux.org/title/Partitioning#Example_layouts"
  echo ""
  echo " $ lsblk -p"
  echo "then find relevant disk partition and run:"
  echo ""
  echo "$ cfdisk /dev/sda"
  echo ""
  echo "[Select lable type] -> gpt"
  echo ""
  echo "Mount point on  Partition Partition type          Suggested size"
  echo "/boot or /efi1  /dev/sda1 EFI system              At least 260 MiB"
  echo "[SWAP]          /dev/sda2 Linux swap              More than 512 MiB"
  echo "/               /dev/sda3 Linux Filesystem        Remainder of the device"
  echo ""
  echo "[Write] and [Quit]"
  echo ""
  echo "MAKE SURE YOU ARE USING [/dev/sda] DEVICE! (otherwise change the code)"
}

print_documentation () {
    echo "Run either $ print_documentation or $ source arch.sh to display this again."

    echo  STEP 1
    echo  Inside Arch ISO installer.
    echo  $ set_base_settings
    echo  ""
    echo  STEP 2
    echo  RUN FIRST CFDISK!
    echo  $ print_partition_documentation
    echo  $ init_mnt_filesystem
    echo  ""
    echo  STEP 3
    echo  Inside /mnt Arch.
    echo  $ install_arch
    echo  ""
    echo  STEP 4
    echo  Back to Arch ISO installer.
    echo  $ "umount -R /mnt"
    echo  $ "poweroff"
    echo  ""
    echo  Unplug the Arch ISO installer.
    echo  Then boot up in existing OS
    echo  ""
    echo  STEP 5
    echo  After reboot.
    echo  As regular user.
    echo  $ install_desktop
    echo  ""
    echo  STEP 6
    echo  Configs
    echo  As regular user.
    echo  $ my_environment
}

print_documentation
