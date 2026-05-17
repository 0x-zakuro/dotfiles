# --- 1. Basic Options ---
autoload -U compinit; compinit  # Enables the advanced tab completion system
setopt correct                  # Auto-corrects minor spelling mistakes (sl -> ls)

# --- 2. History (The Memory) ---
HISTFILE=~/.zsh_history         # Where to save your command history
HISTSIZE=1000           # How many commands to remember in the current session
SAVEHIST=1000           # How many commands to save to the file
setopt HIST_IGNORE_DUPS         # Don't record the same command twice in a row

# --- 3. The Plugins (Visuals & Speed) ---
# Load the packages we just installed with pacman
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- 6. Visual Tab Completion (The Menu) ---
# This makes the Tab key show a selectable menu with colors
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- 4. Your Visuals ---
eval "$(starship init zsh)"
fastfetch

export EDITOR=nvim

# --- Backup Script for github dotfiles ---
backup() {
    echo "backing up dotfiles..."
    
    # 1. Update the files in the backup folder
    cp ~/.zshrc ~/dotfiles/
    rm -rf ~/dotfiles/hypr && cp -r ~/.config/hypr ~/dotfiles/
    pacman -Qqe > ~/dotfiles/packages.txt
    
    # 2. Send to GitHub
    cd ~/dotfiles
    git add .
    git commit -m "Update: $(date)"
    git push
    
    # 3. Go back to where you were
    cd -
    echo "Backup complete!"
}

clean() {
    clear
    echo -e "\n \e[1;34m◆ SYSTEM PURGE PROTOCOL \e[0m"
    echo -e " \e[1;30m──────────────────────────────────────────\e[0m"
    
    # Authenticate sudo upfront so the script never hangs
    sudo -v

    echo -e "\n \e[1;37m[1/7] \e[1;36mPACKAGES  \e[1;30m▶\e[0m Sweeping orphans & package caches..."
    yay -Yc --noconfirm >/dev/null 2>&1
    # Keeps a 2-version rollback buffer just in case
    if command -v paccache &> /dev/null; then
        sudo paccache -rk2 >/dev/null 2>&1
        sudo paccache -ruk0 >/dev/null 2>&1
    else
        yes | yay -Sc >/dev/null 2>&1
    fi

    echo -e " \e[1;37m[2/7] \e[1;36mFLATPAK   \e[1;30m▶\e[0m Clearing unused runtimes..."
    if command -v flatpak &> /dev/null; then
        flatpak uninstall --unused --noninteractive >/dev/null 2>&1
    else
        echo -e "       \e[1;30m└─ Not installed. Skipping.\e[0m"
    fi

    echo -e " \e[1;37m[3/7] \e[1;36mLOGS      \e[1;30m▶\e[0m Vacuuming system & user journals (3d)..."
    sudo journalctl --vacuum-time=3d >/dev/null 2>&1
    journalctl --user --vacuum-time=3d >/dev/null 2>&1

    echo -e " \e[1;37m[4/7] \e[1;36mTRASH     \e[1;30m▶\e[0m Emptying coredumps & Thunar trash..."
    sudo find /var/lib/systemd/coredump/ -type f -delete 2>/dev/null
    # Safely nuke and recreate Thunar's trash to bypass Zsh errors
    rm -rf ~/.local/share/Trash/files ~/.local/share/Trash/info
    mkdir -p ~/.local/share/Trash/{files,info}

    echo -e " \e[1;37m[5/7] \e[1;36mHOME DIR  \e[1;30m▶\e[0m Evicting loose files & rogue folders..."
    # Keeps your ~ root completely minimal
    rm -rf ~/go ~/yay 2>/dev/null

    echo -e " \e[1;37m[6/7] \e[1;36mDEEP CACHE\e[1;30m▶\e[0m Safely purging old app data..."
    # 1. Nuke thumbnails completely
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    # 2. Smart Purge: Delete any cache file not modified in the last 3 days
    find ~/.cache -mindepth 1 -type f -mtime +3 -delete 2>/dev/null
    # 3. Clean up the empty folders left behind
    find ~/.cache -mindepth 1 -type d -empty -delete 2>/dev/null

    echo -e " \e[1;37m[7/7] \e[1;36mDEV & AUR \e[1;30m▶\e[0m Purging compiler bloat & build caches..."
    # 1. Nuke AUR build cache (Massive space saver)
    rm -rf ~/.cache/yay/* 2>/dev/null
    # 2. Nuke Python Pip cache
    rm -rf ~/.cache/pip/* 2>/dev/null
    # 3. Nuke Node.js cache
    rm -rf ~/.npm/_cacache/* 2>/dev/null
    # 4. Nuke Go cache (if installed)
    if command -v go &> /dev/null; then
        go clean -cache -modcache >/dev/null 2>&1
    fi

    echo -e "\n \e[1;32m✔ AGGRESSIVE OPTIMIZATION COMPLETE \e[1;30m| \e[1;37m$(date +%H:%M:%S)\e[0m"
    echo -e " \e[1;36m⚡ System is lean, refreshed, and stripped of bloat.\e[0m\n"
}
