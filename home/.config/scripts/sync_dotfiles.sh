#!/bin/bash

# Stop immediately on errors, undefined variables, or pipe failures
set -euo pipefail

# Define paths explicitly
LOCAL_REPO="$HOME/github/dotfiles"
USB_BACKUP="/run/media/kuro/arch/dotfiles"

echo "🚀 Starting secure 3-way synchronization pipeline..."

# 1. Change to local directory safely
cd "$LOCAL_REPO" || {
  echo "❌ Critical Error: Local directory not found!"
  exit 1
}

# 2. Local Git Commit
echo "📦 Staging local config updates..."
git add .

# Commit only if there are changes
if ! git diff-index --quiet HEAD --; then
  git commit -m "Automated backup: $(date +'%Y-%m-%d %H:%M')"
  echo "☁️ Pushing verified configs to GitHub..."

  # Catch push failures (e.g., no internet, SSH issues)
  if git push origin main; then
    echo "✅ GitHub updated successfully."
  else
    echo "❌ GitHub push failed! Check your network or SSH connection."
    exit 1
  fi
else
  echo "✨ No new configuration changes to push to GitHub."
fi

# 3. Secure Replication to External USB Drive
if [ -d "$USB_BACKUP" ]; then
  echo "💾 Replicating clean files to USB Media..."

  # -r: recursive
  # -L: dereference symlinks (copies actual files, solving exFAT symlink errors!)
  # -t: preserve times
  # -v: verbose display
  # --modify-window=1: crucial fix for exFAT timestamp mismatches
  rsync -rLtv --delete --modify-window=1 --exclude '.git/' "$LOCAL_REPO/" "$USB_BACKUP/"

  echo "🔥 SUCCESS: Home, GitHub, and USB are perfectly identical and safe!"
else
  echo "⚠️ Notification: External USB drive path '$USB_BACKUP' not detected."
  echo "   Landed changes safely in Home and GitHub only."
fi
