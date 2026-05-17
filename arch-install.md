# Arch Linux Installation Guide

**Target setup** — UEFI · Btrfs subvolumes · GRUB · Hyprland · Dual-boot friendly  
Replace all device placeholders (`sda1`, `sda2`, `sda3`) with your actual paths.  
Run `lsblk` at any time to confirm device names.

---

## Installation Phases

```
  LIVE USB                         CHROOT                     POST-BOOT
  ────────────────────────         ──────────────────────     ──────────────────
  1  Pre-install                   6  System config           9   Wi-Fi
  2  Partition                     7  GRUB install           10   Yay + AUR
  3  Format                        8  Reboot                 11   Timeshift
  4  Btrfs subvolumes                                        12   Dev tools
  5  pacstrap + genfstab
```

---

## Phase I — Live USB

---

### 1 · Pre-installation

#### 1.1  Console Font *(HiDPI)*

```bash
setfont -d
```

#### 1.2  Wi-Fi

```bash
iwctl
[iwd]# device list
[iwd]# station <device> scan
[iwd]# station <device> get-networks
[iwd]# station <device> connect <SSID>
exit

ping -c 3 archlinux.org          # verify connectivity
```

#### 1.3  SSH  *(recommended — copy-paste every command from your phone)*

```bash
passwd root                      # set a temporary password for the live session
systemctl enable --now sshd
ip a                             # note the IP address shown
```

Then on your phone (use **Termius** or any SSH client) or another machine:

```bash
ssh root@<ip address>
```

---

### 2 · Partition the Disk

```bash
lsblk                            # identify your drive
cfdisk /dev/<drive>
```

| #  | Label | Device | Size        | Type             |
|----|-------|--------|-------------|------------------|
| 1  | EFI   | sda1   | 512 M – 1 G | EFI System       |
| 2  | Swap  | sda2   | 8 – 12 G    | Linux swap       |
| 3  | Root  | sda3   | Remainder   | Linux filesystem |

```bash
lsblk                            # confirm layout before continuing
```

---

### 3 · Format Partitions

```bash
# EFI — skip entirely if reusing an existing Windows EFI partition
mkfs.fat -F32 /dev/sda1

# Swap
mkswap /dev/sda2
swapon /dev/sda2

# Root
mkfs.btrfs /dev/sda3
```

---

### 4 · Create Btrfs Subvolumes & Mount

`@` = OS root · `@home` = user data.
Timeshift rolls back `@` without ever touching `@home`.

```bash
mount /dev/sda3 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home

umount /mnt
```

**Mount options**

| Option          | Effect                                              |
|-----------------|-----------------------------------------------------|
| `compress=zstd`   | Transparent compression — saves ~20–40 % disk space |
| `noatime`         | Skips read-time writes — reduces SSD wear           |

```bash
mount -o subvol=@,compress=zstd,noatime /dev/sda3 /mnt

mkdir -p /mnt/{home,boot/efi}

mount -o subvol=@home,compress=zstd,noatime /dev/sda3 /mnt/home
mount /dev/sda1 /mnt/boot/efi
```

---

### 5 · Install Base System

```bash
pacstrap /mnt \
  # minimal tty — boots to a shell, nothing more
  base base-devel linux linux-firmware amd-ucode grub efibootmgr networkmanager neovim zsh git \

  # tty + daily-driver utilities — bluetooth, compression, audio, drives, scheduler
  bluez bluez-utils zram-generator pacman-contrib btrfs-progs pipewire-pulse ntfs-3g gvfs gvfs-mtp cronie \

  # hyprland desktop — wm, bar, launcher, notifications, screenshot, clipboard, media
  hyprland hypridle hyprlock hyprpicker waybar rofi-wayland awww swaync nwg-look orchis-theme foot mpv gthumb cliphist wl-clipboard grim slurp brightnessctl zsh-autosuggestions zsh-syntax-highlighting starship fastfetch udisks2 btop fd yazi jq 7zip \

  # dev / data stack — containers, git tuis, notes
  docker docker-compose lazygit lazydocker obsidian
```

---

### 5b · Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

> **Verify** both btrfs entries show `compress=zstd,noatime` in their options column.

---

## Phase II — Chroot

---

### 6 · Configure the System

```bash
arch-chroot /mnt
```

#### 6.1  Timezone

```bash
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
date                             # verify
```

#### 6.2  Locale

```bash
nvim /etc/locale.gen             # uncomment: en_IN.UTF-8 UTF-8
locale-gen
echo "LANG=en_IN.UTF-8" > /etc/locale.conf
```

#### 6.3  Hostname

```bash
echo 'arch' > /etc/hostname
```

#### 6.4  Root Password

```bash
passwd
```

#### 6.5  Create User

```bash
useradd -m -G wheel -s /usr/bin/zsh kuro
passwd kuro
EDITOR=nvim visudo               # uncomment: %wheel ALL=(ALL:ALL) ALL
```

> `-s /usr/bin/zsh` sets Zsh as the default shell — no `chsh` needed later.

#### 6.6  Copy Home Folder from USB

```bash
lsblk
mkdir /usb
mount /dev/sdX1 /usb             # replace sdX1 with your USB partition
cp -r /usb/. /home/kuro/
umount /usb
rmdir /usb
chown -R kuro:kuro /home/kuro
```

#### 6.7  Configure zram

```bash
cat > /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
```

> Without this file, `zram-generator` is installed but does nothing.

#### 6.8  Enable Services

```bash
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable docker
systemctl enable fstrim.timer
```

> `fstrim.timer` runs a weekly TRIM pass on your SSD — keeps write performance healthy
> over time. Uses zero RAM, it's just a scheduled job.

---

### 7 · Install & Configure GRUB

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

> Look for a `microcode` line in the `grub-mkconfig` output — confirms `amd-ucode` was picked up correctly.

---

### 8 · Reboot

```bash
exit                             # exit chroot
umount -R /mnt                   # unmount everything
reboot
```

> Remove the USB drive when the machine powers off.

---

## Phase III — Post-boot

---

### 9 · Connect & Verify

```bash
nmtui                            # TUI for Wi-Fi — NetworkManager starts automatically
```

**Brightness control** — add user to the `video` group so `brightnessctl` works without sudo:

```bash
sudo usermod -aG video kuro
```

> Log out and back in for the group change to take effect.

**Apply GTK theme:**

```bash
nwg-look
```

> Run once to apply the Orchis theme system-wide — sets GTK theme, icon theme, cursor, and font.

---

### 10 · Yay + AUR Packages

*Running as `kuro` in your real session — no `su` gymnastics needed.*

**Build and install Yay:**

```bash
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd ..
rm -rf yay
rm -rf ~/.cache/go              # remove Go build cache left behind by yay compilation
sudo pacman -Rns go             # remove Go toolchain — only needed to build yay
```

**AUR packages:**

```bash
yay -S --needed timeshift-autosnap helium-browser-bin mpv-uosc-git localsend-bin overskride-bin hyprpolkitagent
```

> **timeshift-autosnap** — pacman hook that snapshots before every upgrade automatically.
> Zero manual effort required.

---

### 11 · Timeshift Setup *(once)*

#### 11.1  Initialize Drive

```bash
sudo timeshift --list-devices   # detects Btrfs subvolumes and generates the config file
```

#### 11.2  Configure Timeshift

3 daily snapshots · root `@` only · `@home` excluded.

```bash
UUID=$(lsblk -dno UUID /dev/sda3)

sudo mkdir -p /etc/timeshift
sudo tee /etc/timeshift/timeshift.json > /dev/null << EOF
{
  "backup_device_uuid" : "$UUID",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "btrfs_use_qgroup" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "3",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "exclude" : [],
  "exclude-apps" : []
}
EOF
```

#### 11.3  Configure Autosnap

```bash
sudo nvim /etc/timeshift-autosnap.conf
```

Set these values:

```
maxSnapshots=2
snapshotInterval=0
```

#### 11.4  Enable Cronie

```bash
sudo systemctl enable --now cronie    # starts the service that handles the daily schedule check
```

**Verify:**

```bash
sudo timeshift --list            # view snapshot list
sudo timeshift --check           # check schedule
sudo pacman -S fastfetch         # test pacman hook — autosnap should trigger
```

---

### 12 · Dev Tools Setup

#### 12.1  Docker

```bash
sudo usermod -aG docker kuro
newgrp docker                    # apply without logging out
docker run hello-world           # verify
```

---

*I use Arch, btw.*
