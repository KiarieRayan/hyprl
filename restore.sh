#!/bin/bash

# Ask for backup folder location
read -rp "📦 Enter the path to your backup folder: " backup_dir

# Validate input
if [ ! -d "$backup_dir" ]; then
    echo "❌ Backup folder not found: $backup_dir"
    exit 1
fi

echo "🔄 Restoring configs from $backup_dir"

# List of possible directories and files from the backup to restore
items=(
    "hypr/"
    "hyprpaper/"
    "waybar/"
    "swaylock/"
    "wlogout/"
    "mako/"
    "xdg-desktop-portal/"
    "xdg-desktop-portal-hyprland/"
    "fonts/"
    "starship.toml"
    "gtk-3.0/"
    "gtk-4.0/"
    "bin/"
    "scripts/"
    ".bashrc"
    ".zshrc"
    ".profile"
)

# Restore each one if it exists in the backup
for item in "${items[@]}"; do
    src="$backup_dir/$item"
    dest="$HOME/.config/${item%/}" # Remove trailing slash for destination, except for fonts/scripts
    if [ -e "$src" ]; then
        echo "→ Restoring $item"
        if [[ "$item" == "fonts/" ]]; then
            cp -a "$src" "$HOME/.local/share/"
        elif [[ "$item" == "scripts/" ]]; then
            cp -a "$src" "$HOME/.scripts/"
        elif [[ "$item" == "bin/" ]]; then
            cp -a "$src" "$HOME/.local/"
        elif [[ "$item" == ".bashrc" || "$item" == ".zshrc" || "$item" == ".profile" ]]; then
            cp "$src" "$HOME/"
        else
            mkdir -p "$HOME/.config/"
            cp -a "$src" "$HOME/.config/"
        fi
    fi
done

echo "✅ Restore complete. You may want to restart Hyperland or your session."

