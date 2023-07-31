# Arch

## Arch Setup
See `arch.sh`

Process order:
1. arch.sh
2. environment_setup.sh

## Arch System Maintenance
Complete Guide: https://wiki.archlinux.org/title/System_maintenance

### Read Arch news before upgrade
https://archlinux.org/
Is there any critical update, or should we wait for a critical update after certain time.

### Update regularly and before install a package
Before updating all the packages, you might need to update the keyrings before:
```
sudo pacman -S archlinux-keyring
```

Then update all packages:
```
sudo pacman -Syu
```


### System health
```
systemctl --failed && journalctl -p 3 -b
```

# `archinstall`
