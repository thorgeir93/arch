#!/bin/bash
# Date..: Sun Jun  6 12:40:52 UTC 2021
# ISO V.: 2021.06.01
# Author: Thorgeir Sigurdsson
# Credit: https://wiki.archlinux.org/title/Installation_guide
#         https://www.youtube.com/watch?v=PQgyW10xD8s
# Usage.: source arch.sh
#
# Tested in Virtualbox with EFI enabled in VM settings.
#
# First steps:
#   $ loadkeys is-latin1
#   $ curl https://raw.githubusercontent.com/thorgeir93/arch/main/arch.sh > arch.sh
#   $ source arch.sh
#
# Virtualbox development:
#   * Enable EFI in (Settings>System>Enable EFI).
#   * xrandr -s 1920x1080 # to resize the screen.
#
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
    # /boot or /efi1  /dev/sda1	EFI system              At least 550M
    # [SWAP]	      /dev/sda2	Linux swap		        More than 512M
    # /	              /dev/sda3	Linux Filesystem	    Remainder of the device
    # ```
    lsblk -p
    # then find relevant disk partition and run:
    # $ cfdisk /dev/sda

    ######################
    # DEFINE FILESYSTEMS
    ######################
    # EFI System partition
    mkfs.fat -F32 /dev/sda1

    # Swap partition
    mkswap /dev/sda2
    swapon /dev/sda2

    # Linux Filesystem partition
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
    echo "May want to do $ cat /mnt/etc/fstab"
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
    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg

    # Enable network
    pacman -S networkmanager
    systemctl enable NetworkManager

    # 
    user_run "curl -L $SETUP_SCRIPT_URL > /home/$USERNAME/arch.sh"
    user_run "localectl set-keymap --no-convert is-latin1"

    echo "umount -R /mnt"
    echo "poweroff"
    exit 1
}

install_display_manager () {
    pacman -S lightdm
    pacman -S lightdm-gtk-greeter lightdm-gtk-greeter-settings
    systemctl enable lightdm
}

install_pip () {
    mkdir -p /home/$USERNAME/tmp
    pushd /home/$USERNAME/tmp

    # Credit: https://pip.pypa.io/en/stable/installing/
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py

    popd
}


install_window_manager () {
    #sudo pacman -S qtile
    mkdir -p /home/$USRENAME/git/hub/
    pushd /home/$USERNAME/git/hub
    git clone git://github.com/qtile/qtile.git

    install_pip

    # If you encounter error installing qtile, this could do the trigg:
    # $ python -m pip install --do-deps --ignore-installed cairocffi

    python -m pip install .

    mkdir -p ~/.config/qtile
    cp /usr/share/doc/qtile/default_config.py ~/.config/qtile/

    popd

    # TODO change mod to mod1
    # Maybe copy my config from github!
}

install_aur () {
    # To build packages from aur Arch
    pacman -S base-devel

    git clone https://aur.archlinux.org/yay-git.git
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
    sudo pacman -S rxvt-unicode
    # sudo pacman -S alacritty

    # Utils
    sudo pacman -S chromium git

    # Install latest python
    sudo pacman -S python

    #install_aur

    install_window_manager

    cp /etc/X11/xinit/xinitrc ~/.xinitrc
    echo "nitrogen --restore &" >> ~/.xinitrc
    echo "picom &" >> ~/.xinitrc
    echo "exec qtile start" >> ~/.xinitrc

    # Remove default execution at the bottom.
    # (from last `fi`)
    vim ~/.xinitrc
    # For more details: https://wiki.archlinux.org/title/Xinit

    # Allow Unicode characters in terminal.
    localectl set-keymap --no-convert is-latin1
    localectl set-locale LANG=en_US.UTF-8
    localectl set-x11-keymap is

    # Nice documentation about keymap (fedora):
    #   * https://docs.fedoraproject.org/en-US/Fedora/21/html/System_Administrators_Guide/s2-Setting_the_Keymap.html

    # Trying to set keyboard layout.
    #setxkbmap is # Works
    #loadkeys is-latin1 # Throws error:
    #   couldn't get a file descriptor referring to the console

    #install_display_manager   

    # If not right keymap run
    # See: https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration#Persistent_configuration
    # $ user_run "localectl set-keymap --no-convert is-latin1"

    # Example to start X11 in login.
    # echo '[[ $(fgconsole 2>/dev/null) == 1 ]] && exec startx -- vt1' >> ~/.bash_profile

    # error:
    #   xf86EnableIOPorts: failed to set IOPL for I/O (Operation not permitted)
    #   The XKEYBOARD keymap compler (xkbcomp) reports:
    #   > warning: Could not resolve keysym XF86BrightnessAuto
    #   > warning: Could not resolve keysym XF86DisplayOff
    #   > warning: could not resolve XF86Info
    #   > warning: Could not resolve keysym XF86AspectRatio
    #   > warning: Could not resolve keysym XF86AspectRatioh
    # Fixed by changing in .xinitrc (installation methos may differ)
    #   $ exec qtile
    # TO
    #   $ exec qtile start

    # urxvt - Language settgings:
    # $ localectl status
    #   System Locale: LANG=en_US.UTF-8
    #       VC Keymap: us
    #      X11 Layout: is
    # $ locale
    #   LANG=en_US.UTF-8
    #   LC_CTYPE="en_US.UTF-8"
    #   LC_NUMERIC="en_US.UTF-8"
    #   LC_TIME="en_US.UTF-8"
    #   LC_COLLATE="en_US.UTF-8"
    #   LC_MONETARY="en_US.UTF-8"
    #   LC_MESSAGES="en_US.UTF-8"
    #   LC_PAPER="en_US.UTF-8"
    #   LC_NAME="en_US.UTF-8"
    #   LC_ADDRESS="en_US.UTF-8"
    #   LC_TELEPHONE="en_US.UTF-8"
    #   LC_MEASUREMENT="en_US.UTF-8"
    #   LC_IDENTIFICATION="en_US.UTF-8"
    #   LC_ALL=

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
  echo "In case of disk which already have partition table configure e.g. with DOS table:"
  echo "$ fdisk /dev/sda"
  echo "[delete all partition using 'd']"
  echo "[Create a new empty GPT partition table -> hit 'g']"
  echo ""
  echo ""
  echo "$ cfdisk /dev/sda"
  echo ""
  echo "[Select label type] -> gpt"
  echo ""
  echo "Mount point on  Partition Partition type          Suggested size"
  echo "/boot or /efi1  /dev/sda1 EFI system              At least 550M"
  echo "[SWAP]          /dev/sda2 Linux swap              More than 2G"
  echo "/               /dev/sda3 Linux Filesystem        Remainder of the device"
  echo ""
  echo "[Write] and [Quit]"
  echo ""
  echo "MAKE SURE YOU ARE USING [/dev/sda] DEVICE in the code! (otherwise change the code)"
}

print_documentation () {
    echo "I Recommend to have the following documenation on the side while installing."
    echo "------------------"
    echo "First steps"
    echo "------------------"
    echo   MAKE SURE YOU HAVE INTERNET CONNECTION
    echo   $ loadkeys is-latin1
    echo '  (for regular user) $ localectl set-keymap --no-convert is-latin1'
    echo " $ curl https://raw.githubusercontent.com/thorgeir93/arch/main/arch.sh > arch.sh"
    echo   $ source arch.sh
    echo ""
    echo "Run either $ print_documentation or $ source arch.sh to display this again."
    echo ""
    echo STEP 1
    echo Inside Arch ISO installer.
    echo $ set_base_settings
    echo ""
    echo STEP 2
    echo $ print_partition_documentation
    echo Make sure you run first cfdisk!
    echo $ init_mnt_filesystem
    echo Then run $ arch-chroot /mnt
    echo ""
    echo STEP 3
    echo Inside /mnt Arch.
    echo Download the current script again.
    echo $ install_arch
    echo    1. Uncomment en_US.UTF-8 UTF-8
    echo    2. Set root password
    echo    3. Set user password.
    echo    4. Uncomment '%wheel ALL=(ALL) ALL'
    echo ""
    echo STEP 4
    echo Go back to Arch ISO installer '$ exit'
    echo $ "umount -R /mnt"
    echo $ "shutdown now"
    echo ""
    echo Unplug the Arch ISO installer.
    echo Then boot up in existing OS
    echo ""
    echo STEP 5
    echo "After reboot (as regular user)."
    echo $ install_desktop
    echo "   1. In .xinit -> Remove default exec"
    echo $ reboot
    echo $ xrandr -s 1
    echo ""
    echo STEP 6
    echo Configs
    echo As regular user.
    echo $ my_environment
}

print_documentation
