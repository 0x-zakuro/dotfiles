# dotfiles

Minimal, keyboard-driven Arch Linux setup running Hyprland on Wayland. Oxocarbon-inspired color scheme across the entire stack — terminal, editor, bar, and shell prompt. No bloat, no desktop environment.

---

![desktop + waybar + swaync](preview/desktop_waybar_swaync.png)
![foot](preview/foot.png)
![lazyvim](preview/lazyvim.png)


---

## Stack

| Component        | Tool                               |
|------------------|------------------------------------|
| OS               | Arch Linux                         |
| Window Manager   | Hyprland (Wayland, XWayland off)   |
| Bar              | Waybar — minimal pill + mpris      |
| Terminal         | Foot                               |
| Shell            | Zsh + Starship                     |
| Editor           | Neovim (LazyVim)                   |
| Launcher         | Rofi                               |
| Notifications    | Swaync                             |
| File Manager     | Yazi                               |
| Wallpaper        | Awww                               |
| GTK Theme        | Orchis                             |
| Cursor           | Bibata Modern Classic              |
| Font             | Dank Mono Nerd Font                |
| Color Scheme     | Oxocarbon                          |

---

## Structure

```
Home/
└── .config/
    ├── fastfetch/        # system info layout + custom logo
    ├── foot/             # terminal — Oxocarbon colors, Dank Mono
    ├── hypr/             # hyprland, hypridle, hyprlock
    ├── nvim/             # LazyVim — Oxocarbon theme
    ├── rofi/             # launcher
    ├── scripts/          # screenshot, kill-active, utilities
    ├── swaync/           # notification center + control panel
    ├── wallpaper/        # wallpapers per workspace
    ├── waybar/           # pill-style bar — clock, workspaces, battery, mpris
    ├── zsh/              # aliases, exports, plugins
    └── starship.toml     # prompt — git, python, node, docker, aws, k8s context
```

---

## Hyprland Highlights

- **XWayland disabled** — pure Wayland
- **Dwindle layout** with smart splits and preserved ratios
- **Blur + rounded corners** (5px), no borders, no shadows
- **Opacity** — 0.95 active / 0.87 inactive
- **VRR enabled** for variable refresh rate displays

### Keybindings

| Key                     | Action                         |
|-------------------------|--------------------------------|
| `Super + A`               | Terminal (foot)                |
| `Super + S`               | Editor (Neovim)                |
| `Super + D`               | Browser (Helium)               |
| `Super + W`               | Launcher (Rofi)                |
| `Super + Q`               | Close window                   |
| `Super + F`               | Fullscreen                     |
| `Super + C`               | Toggle float                   |
| `Super + L`               | Lock screen (Hyprlock)         |
| `Super + Shift + S`       | Screenshot copy to clipboard   |
| `Super + Shift + Ctrl + S`| Screenshot saved to file       |
| `Print`                   | Full screenshot saved to file  |
| `Super + H / L`           | Switch workspace               |
| `Super + 1–0`             | Jump to workspace              | 
| `Super + Arrow`           | Focus window                   |
| `Super + Shift + Arrow`   | Move window                    |
| `Super + Alt + Arrow`     | Resize window                  |

---

## Waybar — Pill Design

Three floating pill groups anchored to the top bar:

- **Left** — clock · hardware group (CPU, RAM, disk) · workspaces
- **Center** — focused window title
- **Right** — MPRIS media · battery · notification toggle

---

## Reliability

- **Btrfs** with `@` and `@home` subvolumes — system rollbacks without touching user data
- **Timeshift** with `timeshift-autosnap` — automatic snapshot before every pacman upgrade
- **zram** swap (zstd, `ram / 2`) — effectively doubles usable memory
- **fstrim.timer** — weekly SSD TRIM for sustained write performance

---

## Installation

Full step-by-step Arch install guide included — covers UEFI, Btrfs subvolumes, GRUB, Hyprland, Timeshift, and dual-boot setup.

See [`arch-install.md`](arch-install.md).

Clone and symlink configs:

```bash
git clone git@github.com:Mayank-cs-2004/dotfiles.git
cp -r dotfiles/Home/. ~/
```

---

*I use Arch, btw.*
