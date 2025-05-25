WALLPAPER_DIR="$HOME/.config/hypr/backgrounds"
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)

# Preload the wallpaper
hyprctl hyprpaper preload "$RANDOM_WALLPAPER"

# Wait until the wallpaper is actually preloaded
# Retry for up to ~1 second
for i in {1..10}; do
    sleep 0.1
    hyprctl hyprpaper ls | grep -Fq "$RANDOM_WALLPAPER" && break
done

# Apply the wallpaper
hyprctl hyprpaper wallpaper ",$RANDOM_WALLPAPER"
