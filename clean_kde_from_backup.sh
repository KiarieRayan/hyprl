#!/bin/bash

backup_dir="$1"

if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
    echo "❌ Provide a valid backup directory path."
    exit 1
fi

echo "🧹 Cleaning KDE-related files from: $backup_dir"

# Remove KDE config dirs
rm -rf "$backup_dir"/kde* "$backup_dir"/plasma* "$backup_dir"/xdg-desktop-portal-kde/

# Remove KDE autostart entries
if [ -d "$backup_dir/autostart" ]; then
    find "$backup_dir/autostart" -iname "*kde*.desktop" -exec rm -v {} \;
fi

# Remove KDE systemd services
if [ -d "$backup_dir/systemd/user" ]; then
    find "$backup_dir/systemd/user" -iname "*kde*" -exec rm -v {} \;
fi

echo "✅ KDE cleanup complete in $backup_dir"

