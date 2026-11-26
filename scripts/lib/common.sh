# Shared helpers for i3dots scripts and install.sh. Source it, do not run it.
# Expects REPO to be set by the caller.

DOTS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTS_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/i3dots"
WAL_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wal"
DOTS_SETTINGS="$DOTS_CONFIG/i3dots/settings"
DEFAULT_WALLPAPER="$REPO/wallpapers/mountain-lake.jpg"

# dots_setting <key> <default> -> prints stored value or default
dots_setting() {
    local value
    value=$(sed -n "s/^$1=//p" "$DOTS_SETTINGS" 2>/dev/null | tail -n 1)
    printf '%s' "${value:-$2}"
}

# Interface language: "en" or "es"
DOTS_LANG="$(dots_setting language en)"

# L "English text" "Texto en español"
L() {
    if [[ "$DOTS_LANG" == es ]]; then printf '%s' "$2"; else printf '%s' "$1"; fi
}

# Ensures ~/.cache/wal/ has fallback palette files so Polybar, Rofi, Dunst,
# Cava and dots-media never fail before Pywal has run for the first time.
ensure_wal_fallbacks() {
    mkdir -p "$WAL_CACHE" "$DOTS_CACHE"
    [[ -f "$WAL_CACHE/polybar-colors.ini" ]] || cp "$REPO/config/polybar/colors.ini" "$WAL_CACHE/polybar-colors.ini"
    [[ -f "$WAL_CACHE/rofi-colors.rasi" ]]   || cp "$REPO/config/rofi/colors.rasi"   "$WAL_CACHE/rofi-colors.rasi"
    [[ -f "$WAL_CACHE/dunstrc" ]]            || cp "$REPO/config/dunst/dunstrc"      "$WAL_CACHE/dunstrc"
    [[ -f "$WAL_CACHE/dots-media.css" ]]     || cp "$REPO/config/dots-media/colors.css" "$WAL_CACHE/dots-media.css"
    if [[ ! -f "$DOTS_CACHE/cava.conf" ]]; then
        cp "$REPO/config/cava/config" "$DOTS_CACHE/cava.conf"
    fi
}

# Prints every wallpaper folder (one per line): the repo's wallpapers/ plus the
# user's XDG Pictures folder (~/Imágenes, ~/Pictures...). Subfolders such as
# Pictures/Wallpapers are covered because Nitrogen and --random recurse.
wallpaper_dirs() {
    local pics="" d
    command -v xdg-user-dir >/dev/null && pics="$(xdg-user-dir PICTURES 2>/dev/null || true)"
    [[ "$pics" == "$HOME" ]] && pics=""
    {
        printf '%s\n' "$REPO/wallpapers"
        for d in "$pics" "$HOME/Imágenes" "$HOME/Pictures"; do
            [[ -n "$d" && -d "$d" ]] && readlink -f "$d"
        done
    } | awk '!seen[$0]++'
}

# Makes sure Nitrogen's browser lists every wallpaper_dirs folder, keeping any
# folder the user added manually from the Nitrogen preferences.
sync_nitrogen_dirs() {
    local cfg="$DOTS_CONFIG/nitrogen/nitrogen.cfg" current merged d
    [[ -f "$cfg" ]] || return 0
    current=$(sed -n 's/^dirs=//p' "$cfg" | head -n 1)
    merged="$current"
    while IFS= read -r d; do
        [[ ";$merged" == *";$d;"* ]] || merged+="$d;"
    done < <(wallpaper_dirs)
    [[ "$merged" == "$current" ]] && return 0
    if grep -q '^dirs=' "$cfg"; then
        local tmp; tmp=$(mktemp)
        awk -v v="$merged" '/^dirs=/{print "dirs=" v; next} {print}' "$cfg" >"$tmp" && mv "$tmp" "$cfg"
    else
        printf 'dirs=%s\n' "$merged" >>"$cfg"
    fi
}

# Returns the active wallpaper saved by Nitrogen, or the default repo wallpaper.
nitrogen_current_wallpaper() {
    local cfg="$DOTS_CONFIG/nitrogen/bg-saved.cfg"
    local wall=""
    if [[ -r "$cfg" ]]; then
        wall=$(sed -n 's/^file=//p' "$cfg" | head -n 1)
    fi
    if [[ -n "$wall" && -f "$wall" ]]; then
        printf '%s' "$wall"
    else
        printf '%s' "$DEFAULT_WALLPAPER"
    fi
}
