# Arch

## Arch Setup
See `arch.sh`

## Arch System Maintenance
Complete Guide: https://wiki.archlinux.org/title/System_maintenance

### Read Arch news before upgrade
https://archlinux.org/
Is there any critical update, or should we wait for a critical update after certain time.

### Update regularly and before install a package
Always use:
```
pacman -Syu
```

### System health
```
systemctl --failed && journalctl -p 3 -b
```
