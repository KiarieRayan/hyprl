#!/usr/bin/env bash
grim -g "$(slurp)" "$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
notify-send "Screenshot saved 📸"
