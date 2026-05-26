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

#### 1.3  SSH *(recommended)*

```bash
passwd root                      # set temporary root password
systemctl enable --now sshd
ip a                             # note the IP address
```

Connect from another machine:

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
lsblk                            # confirm layout
```

---

### 3 · Format Partitions

```bash
# EFI — skip if reusing an existing Windows EFI partition
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
Timeshift snapshots `@` independently — `@home` is never touched on rollback.

```bash
mount /dev/sda3 /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home

umount /mnt
```

**Mount options**

| Option        | Effect                                              |
|---------------|-----------------------------------------------------|
| `compress=zstd` | Transparent compression — saves ~20–40 % disk space |
| `noatime`       | Skips read-time writes — reduces SSD wear           |

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
  # base
  base base-devel linux linux-firmware amd-ucode grub efibootmgr networkmanager neovim zsh git \

  # utilities — bluetooth, compression, audio, drives, scheduler
  bluez bluez-utils zram-generator pacman-contrib btrfs-progs pipewire-pulse ntfs-3g gvfs gvfs-mtp cronie \

  # hyprland desktop — wm, bar, launcher, notifications, screenshot, clipboard, media
  hyprland hypridle hyprlock hyprpicker waybar rofi-wayland awww nwg-look foot mpv gthumb cliphist wl-clipboard grim slurp brightnessctl zsh-autosuggestions zsh-syntax-highlighting starship fastfetch udisks2 btop fd yazi jq unzip \

  # dev stack — containers, tuis, notes
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

#### 6.6  Clone Dotfiles

```bash
git clone https://github.com/0x-zakuro/dotfiles.git /tmp/dotfiles
cp -r /tmp/dotfiles/home/. /home/kuro/
rm -rf /tmp/dotfiles
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

#### 6.8  Enable Services

```bash
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable docker
systemctl enable fstrim.timer    # weekly SSD TRIM
```

---

### 7 · Install & Configure GRUB

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

> Verify a `microcode` line appears in the `grub-mkconfig` output — confirms `amd-ucode` was picked up.

---

### 8 · Reboot

```bash
exit                             # exit chroot
umount -R /mnt                   # unmount all
reboot
```

---

## Phase III — Post-boot

---

### 9 · Connect & Verify

```bash
nmtui                            # connect to Wi-Fi
```

```bash
sudo usermod -aG video kuro      # brightnessctl without sudo — re-login to apply
```

```bash
nwg-look                         # apply GTK theme, icons, cursor, font
```

---

### 10 · Yay + AUR Packages

**Build and install Yay:**

```bash
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si
cd ..
rm -rf yay
rm -rf ~/.cache/go              # remove Go build cache
sudo pacman -Rns go             # remove Go toolchain
```

**AUR packages:**

```bash
yay -S --needed timeshift-autosnap helium-browser-bin mpv-uosc-git hyprpolkitagent
```

> **timeshift-autosnap** — hooks into pacman and snapshots before every upgrade automatically.

---

### 11 · Timeshift Setup *(once)*

#### 11.1  Initialize

```bash
sudo timeshift --list-devices   # generates /etc/timeshift/timeshift.json
```

#### 11.2  Configure

3 daily snapshots · `@` only · `@home` excluded.

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

```
maxSnapshots=2
snapshotInterval=0
```

#### 11.4  Enable Cronie

```bash
sudo systemctl enable --now cronie
```

**Verify:**

```bash
sudo timeshift --list            # list snapshots
sudo timeshift --check           # check schedule
sudo pacman -S fastfetch         # trigger autosnap hook
```

---

### 12 · Dev Tools Setup

#### 12.1  Docker

```bash
sudo usermod -aG docker kuro
newgrp docker                    # apply without re-login
docker run hello-world           # verify
```

---

*I use Arch, btw.*
