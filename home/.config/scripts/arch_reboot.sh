#!/bin/bash
# Tell the BIOS to boot GRUB (0002) just this once
pkexec efibootmgr --bootnext 0002 && systemctl reboot