#!/usr/bin/env bash
# Automated installer for i3dots on Arch Linux (and Arch-based distributions).
#
#   ./install.sh                     install packages (incl. Brave), link configs, init Nitrogen + Pywal
#   ./install.sh --no-packages       only link configs and initialize Nitrogen + Pywal
#   ./install.sh --lang es           interface language: en (English) or es (Español)
#   ./install.sh --kb-layout latam   X11 keyboard layout(s), e.g. us, latam, "latam,us"
#   ./install.sh --kb-variant intl   keyboard variant ("" for none)
#   ./install.sh --kb-options grp:ctrl_space_toggle   XKB options ("" for none)
#   ./install.sh --wallpaper /path   initial wallpaper for Nitrogen + Pywal
#   ./install.sh --dry-run           print what would be done without changing anything
#   ./install.sh --yes               unattended: no questions, pacman/AUR run with --noconfirm
#
# Existing configs in ~/.config, ~/.local/bin or ~/ are safely moved to
# ~/.config/i3dots-backup-<date>/ before creating symlinks to this repository.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$REPO/scripts/lib/common.sh"

CFG="$DOTS_CONFIG"
BIN="$HOME/.local/bin"
BACKUP="$CFG/i3dots-backup-$(date +%Y%m%d-%H%M%S)"

CONFIGS=(i3 polybar picom rofi dunst kitty fastfetch atuin dots-media wal gtk-3.0 gtk-4.0)
HOME_FILES=(.zshrc .zprofile .p10k.zsh .xinitrc)
SCRIPTS=(
    dots-monitors
    dots-monitor-watch
    dots-polybar
    dots-cava
    dots-pywal
    dots-wallpaper
    dots-media
    dots-mediakey
    dots-powermenu
    dots-lock
    dots-keybinds
    dots-input
    dots-bluetooth
    dots-clipboard
    dots-update
)

# Zsh framework, theme and plugins (cloned with git)
OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_REPOS=(
    "$OMZ_DIR|https://github.com/ohmyzsh/ohmyzsh.git"
    "$OMZ_DIR/custom/themes/powerlevel10k|https://github.com/romkatv/powerlevel10k.git"
    "$OMZ_DIR/custom/plugins/zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
    "$OMZ_DIR/custom/plugins/zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

PACKAGES=1
DRY_RUN=0
ASSUME_YES=0
LANG_CHOICE=""
KB_LAYOUT=""
WALLPAPER_ARG=""
unset KB_VARIANT KB_OPTIONS

green=$'\e[32m'; yellow=$'\e[33m'; red=$'\e[31m'; bold=$'\e[1m'; reset=$'\e[0m'
step()  { echo "${bold}${green}==>${reset}${bold} $*${reset}"; }
warn()  { echo "${yellow}  $(L "warning" "aviso"): $*${reset}"; }
die()   { echo "${red}  error: $*${reset}" >&2; exit 1; }
run()   { if (( DRY_RUN )); then echo "    [dry-run] $*"; else "$@"; fi; }
short() { echo "${1/#$HOME/\~}"; }

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while (($#)); do
    case "$1" in
        --no-packages) PACKAGES=0 ;;
        --dry-run)     DRY_RUN=1 ;;
        -y|--yes)      ASSUME_YES=1 ;;
        --lang)        LANG_CHOICE="${2:?missing language (en|es)}"; shift ;;
        --kb-layout)   KB_LAYOUT="${2:?missing keyboard layout}"; shift ;;
        --kb-variant)  KB_VARIANT="${2?missing keyboard variant}"; shift ;;
        --kb-options)  KB_OPTIONS="${2?missing keyboard options}"; shift ;;
        --wallpaper)   WALLPAPER_ARG="${2:?missing wallpaper path}"; shift ;;
        -h|--help)     usage ;;
        *)             die "unknown option: $1 (see --help)" ;;
    esac
    shift
done

NOCONFIRM=(); (( ASSUME_YES )) && NOCONFIRM=(--noconfirm)

[[ $EUID -eq 0 ]] && die "do not run the installer as root; it asks for sudo when needed"
command -v pacman >/dev/null || die "this installer is for Arch-based distributions (pacman not found)"

# --- 0. Preferences: interface language and X11 keyboard layout ---
interactive=0; [[ -t 0 ]] && (( ! ASSUME_YES )) && interactive=1

has_setting() { grep -q "^$1=" "$DOTS_SETTINGS" 2>/dev/null; }
system_x11() { { localectl status 2>/dev/null || true; } | sed -n "s/^ *X11 $1: //p" | { grep -vxE '\(unset\)|n/a' || true; }; }

if has_setting language; then
    default_lang=$DOTS_LANG
elif [[ "${LANG:-}" == es* ]]; then
    default_lang=es
else
    default_lang=en
fi

if [[ -z "$LANG_CHOICE" ]]; then
    LANG_CHOICE=$default_lang
    if (( interactive )); then
        [[ $default_lang == es ]] && default_num=2 || default_num=1
        echo "${bold}Interface language / Idioma de la interfaz${reset}"
        echo "  1) English"
        echo "  2) Español"
        read -rp "Choose / Elige [$default_num]: " answer
        case "${answer:-$default_num}" in
            1|en) LANG_CHOICE=en ;;
            2|es) LANG_CHOICE=es ;;
            *)    die "invalid option: $answer" ;;
        esac
    fi
fi
[[ "$LANG_CHOICE" == en || "$LANG_CHOICE" == es ]] || die "language must be 'en' or 'es'"
DOTS_LANG=$LANG_CHOICE

XKB_LIST=/usr/share/X11/xkb/rules/base.lst
xkb_section() { sed -n "/^! $1\$/,/^\$/{/^ /p}" "$XKB_LIST"; }
valid_keyboard() {
    local known i
    [[ -r "$XKB_LIST" ]] || return 2
    known=$(xkb_section layout | awk '{print $1}')
    IFS=, read -ra layouts <<<"$1"
    IFS=, read -ra variants <<<"$2"
    for i in "${!layouts[@]}"; do
        grep -qx "${layouts[i]}" <<<"$known" || { warn "$(L "unknown layout" "distribución desconocida"): ${layouts[i]}"; return 1; }
        if [[ -n "${variants[i]:-}" ]] &&
           ! xkb_section variant | awk -v l="${layouts[i]}:" '$2 == l {print $1}' | grep -qx "${variants[i]}"; then
            warn "$(L "unknown variant" "variante desconocida"): ${variants[i]} (${layouts[i]})"; return 1
        fi
    done
}

default_layout=$(dots_setting kb_layout "$(system_x11 Layout)"); default_layout=${default_layout:-us}
if has_setting kb_variant; then
    default_variant=$(dots_setting kb_variant "")
else
    default_variant=$(system_x11 Variant)
fi

KB_UNVERIFIED=0
while :; do
    layout=${KB_LAYOUT:-$default_layout}
    if [[ -n "$KB_LAYOUT" && "$KB_LAYOUT" != "$default_layout" ]]; then
        variant=${KB_VARIANT-}
    else
        variant=${KB_VARIANT-$default_variant}
    fi
    if (( interactive )) && [[ -z "$KB_LAYOUT" ]]; then
        echo "${bold}$(L "Keyboard layout" "Distribución de teclado")${reset}"
        echo "  $(L "Examples: us, latam, es, de, fr. Several layouts: latam,us (Ctrl + Space switches)." "Ejemplos: us, latam, es, de, fr. Varias: latam,us (Ctrl + Espacio cambia entre ellas).")"
        read -rp "  $(L "Layout" "Distribución") [$default_layout]: " answer; layout=${answer:-$default_layout}
        if [[ -z "${KB_VARIANT+x}" ]]; then
            [[ "$layout" == "$default_layout" ]] && suggested=$default_variant || suggested=""
            read -rp "  $(L "Variant (optional, e.g. intl, dvorak)" "Variante (opcional, ej. intl, dvorak)") [$suggested]: " answer
            variant=${answer:-$suggested}
        fi
    fi
    valid_keyboard "$layout" "$variant" && rc=0 || rc=$?
    (( rc == 0 )) && break
    if (( rc == 2 )); then KB_UNVERIFIED=1; break; fi
    (( interactive )) && [[ -z "$KB_LAYOUT" ]] || die "$(L "invalid keyboard layout" "distribución de teclado inválida"): $layout $variant"
done

resolve_options() {
    if [[ -n "${KB_OPTIONS+x}" ]]; then
        options=$KB_OPTIONS
    else
        options=$(dots_setting kb_options "")
        if [[ "$layout" == *,* ]]; then
            [[ "$options" == *grp:* ]] || options="${options:+$options,}grp:ctrl_space_toggle"
        else
            options=$(tr ',' '\n' <<<"$options" | { grep -v '^grp:' || true; } | paste -sd, -)
        fi
    fi
}

write_settings() {
    local text="# Preferences for i3dots, written by install.sh. Edit manually if needed,
# then run 'dots-input' or reload i3.
language=$DOTS_LANG
kb_layout=$layout
kb_variant=$variant
kb_options=$options"
    run mkdir -p "$(dirname "$DOTS_SETTINGS")"
    if (( DRY_RUN )); then
        echo "    [dry-run] $(L "write" "escribir") $(short "$DOTS_SETTINGS"):"; sed 's/^/      /' <<<"$text"
    else
        printf '%s\n' "$text" >"$DOTS_SETTINGS"
    fi
}

resolve_options
write_settings
step "$(L "Language" "Idioma"): $(L "English" "Español")"
step "$(L "Keyboard" "Teclado"): $layout${variant:+ ($variant)}${options:+ [$options]}"
(( KB_UNVERIFIED )) && echo "    $(L "(will be checked after installing packages)" "(se comprobará después de instalar los paquetes)")"

can_sudo() { (( DRY_RUN )) || [[ -t 0 ]] || sudo -n true 2>/dev/null; }
NO_SUDO_MSG=$(L "needs sudo, but there is no terminal to type the password; run ./install.sh from a terminal" \
                "necesita sudo, pero no hay una terminal donde escribir la contraseña; ejecuta ./install.sh desde una terminal")

read_list() { grep -vE '^\s*(#|$)' "$1" | sed 's/#.*//' | awk '{print $1}'; }
missing_packages() { pacman -T "$@" 2>/dev/null || true; }

# --- 1. Official & AUR packages (including automatic Brave installation) ---
if (( PACKAGES )); then
    step "$(L "Installing packages from official Arch repositories" "Instalando paquetes de los repositorios oficiales de Arch")"
    mapfile -t official < <(read_list "$REPO/packages/pacman.txt")
    mapfile -t todo < <(missing_packages "${official[@]}")
    if (( ${#todo[@]} == 0 )); then
        echo "    $(L "all installed" "todos instalados")"
    else
        echo "    $(L "missing" "faltan"): ${todo[*]}"
        can_sudo || die "pacman $NO_SUDO_MSG"
        run sudo pacman -S --needed "${NOCONFIRM[@]}" "${todo[@]}" ||
            die "$(L "pacman could not install the packages. Run ./install.sh again to resume." \
                     "pacman no pudo instalar los paquetes. Ejecuta ./install.sh de nuevo para continuar.")"
    fi

    step "$(L "Installing AUR packages (Nitrogen, Pywal, Brave, i3lock-color, tty-clock, greenclip)" "Instalando paquetes del AUR (Nitrogen, Pywal, Brave, i3lock-color, tty-clock, greenclip)")"
    mapfile -t aur_raw < <(read_list "$REPO/packages/aur.txt")
    aur_filtered=()
    for pkg in "${aur_raw[@]}"; do
        # Skip brave-bin if Brave is already installed via any package
        if [[ "$pkg" == "brave-bin" ]] && { command -v brave >/dev/null 2>&1 || command -v brave-browser >/dev/null 2>&1; }; then
            echo "    $(L "already installed" "ya instalado"): brave"
            continue
        fi
        # Skip python-pywal if `wal` is already provided (e.g. python-pywal16)
        if [[ "$pkg" == "python-pywal" ]] && command -v wal >/dev/null 2>&1; then
            echo "    $(L "already installed" "ya instalado"): pywal ($(command -v wal))"
            continue
        fi
        # Skip rofi-greenclip if `greenclip` is already installed
        if [[ "$pkg" == "rofi-greenclip" ]] && command -v greenclip >/dev/null 2>&1; then
            echo "    $(L "already installed" "ya instalado"): greenclip"
            continue
        fi
        aur_filtered+=("$pkg")
    done

    todo=()
    if (( ${#aur_filtered[@]} > 0 )); then
        mapfile -t todo < <(missing_packages "${aur_filtered[@]}")
    fi

    if (( ${#todo[@]} == 0 )); then
        echo "    $(L "all installed" "todos instalados")"
    else
        echo "    $(L "missing" "faltan"): ${todo[*]}"
        can_sudo || die "AUR $NO_SUDO_MSG"
        helper=""
        for h in paru yay; do command -v "$h" >/dev/null && { helper=$h; break; }; done
        if [[ -z "$helper" ]]; then
            answer=""
            (( ASSUME_YES )) || read -rp "  $(L "Neither paru nor yay found. Install yay-bin from the AUR? [Y/n] " "No hay paru ni yay. ¿Instalar yay-bin desde el AUR? [S/n] ")" answer
            if [[ ! "$answer" =~ ^[nN] ]]; then
                run sudo pacman -S --needed "${NOCONFIRM[@]}" base-devel git
                tmp=$(mktemp -d)
                run git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
                if (( DRY_RUN )); then
                    echo "    [dry-run] (cd $tmp/yay-bin && makepkg -si ${NOCONFIRM[*]})"
                else
                    (cd "$tmp/yay-bin" && makepkg -si "${NOCONFIRM[@]}")
                fi
                rm -rf "$tmp"
                helper=yay
            fi
        fi
        if [[ -n "$helper" ]]; then
            run "$helper" -S --needed "${NOCONFIRM[@]}" "${todo[@]}" ||
                warn "$(L "some AUR packages failed; installation continues. Retry later with: $helper -S ${todo[*]}" \
                          "fallaron algunos paquetes del AUR; la instalación continúa. Reinténtalo después con: $helper -S ${todo[*]}")"
        else
            warn "$(L "skipped AUR packages" "se omitieron los paquetes del AUR"): ${todo[*]}"
        fi
    fi
else
    step "$(L "Skipping package installation (--no-packages)" "Omitiendo la instalación de paquetes (--no-packages)")"
fi

if (( KB_UNVERIFIED && ! DRY_RUN )); then
    valid_keyboard "$layout" "$variant" && rc=0 || rc=$?
    if (( rc == 1 )); then
        warn "$(L "falling back to the 'us' keyboard layout" "se usará la distribución de teclado 'us'")"
        layout=us; variant=""; resolve_options; write_settings
    elif (( rc == 2 )); then
        warn "$(L "could not verify keyboard layout (xkeyboard-config not found)" "no se pudo comprobar la distribución de teclado (no se encontró xkeyboard-config)")"
    fi
fi

# --- 2. Config & script symlinks (with automatic backup) ---
link() {
    local src=$1 dst=$2
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        echo "    $(L "already linked" "ya enlazado"): $(short "$dst")"
        return
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        run mkdir -p "$BACKUP"
        run mv "$dst" "$BACKUP/"
        echo "    $(L "backed up" "respaldado"): $(short "$dst") -> $(short "$BACKUP")/"
    fi
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    echo "    $(L "linked" "enlazado"): $(short "$dst") -> $(short "$src")"
}

step "$(L "Linking configs into" "Enlazando configuraciones en") $(short "$CFG")"
for c in "${CONFIGS[@]}"; do
    link "$REPO/config/$c" "$CFG/$c"
done

# Cava uses a runtime cache config merged with Pywal so the git repo stays clean
run mkdir -p "$DOTS_CACHE"
if (( ! DRY_RUN )) && [[ ! -f "$DOTS_CACHE/cava.conf" ]]; then
    cp "$REPO/config/cava/config" "$DOTS_CACHE/cava.conf"
fi
link "$DOTS_CACHE/cava.conf" "$CFG/cava/config"

step "$(L "Linking scripts into" "Enlazando scripts en") $(short "$BIN")"
for s in "${SCRIPTS[@]}"; do
    run chmod +x "$REPO/scripts/$s"
    link "$REPO/scripts/$s" "$BIN/$s"
done

# --- 3. Zsh: shell files, Oh My Zsh and Powerlevel10k ---
step "$(L "Setting up zsh and Oh My Zsh" "Configurando zsh y Oh My Zsh")"
for f in "${HOME_FILES[@]}"; do
    link "$REPO/home/$f" "$HOME/$f"
done

for entry in "${OMZ_REPOS[@]}"; do
    dir=${entry%%|*}; url=${entry#*|}
    if [[ -d "$dir/.git" ]]; then
        echo "    $(L "already installed" "ya instalado"): $(short "$dir")"
    elif [[ -e "$dir" ]]; then
        warn "$(L "exists but is not a git clone, left as is" "existe pero no es un clon de git, se deja como está"): $(short "$dir")"
    else
        run git clone -q --depth 1 "$url" "$dir"
        echo "    $(L "installed" "instalado"): $(short "$dir")"
    fi
done

zsh_path=$(command -v zsh || true)
login_shell=$(getent passwd "$USER" | cut -d: -f7)
if [[ -z "$zsh_path" ]]; then
    warn "$(L "zsh is not installed; default shell unchanged" "zsh no está instalado; no se cambió la shell por defecto")"
elif [[ "$login_shell" == */zsh ]]; then
    echo "    $(L "default shell" "shell por defecto"): $login_shell"
elif [[ -n "${DOTS_UPDATING:-}" ]]; then
    :
else
    answer=""
    if (( interactive )); then
        read -rp "    $(L "Make zsh your default shell (instead of $login_shell)? [Y/n] " "¿Usar zsh como shell por defecto (en lugar de $login_shell)? [S/n] ")" answer
    fi
    if [[ ! "$answer" =~ ^[nN] ]] && ! can_sudo; then
        warn "chsh $NO_SUDO_MSG"
    elif [[ ! "$answer" =~ ^[nN] ]]; then
        run sudo chsh -s "$zsh_path" "$USER"
        login_shell=$zsh_path
        echo "    $(L "default shell" "shell por defecto"): $zsh_path"
    fi
fi

# --- 4. User folders, default apps (Thunar & Brave) & Bluetooth service ---
step "$(L "User folders and default apps" "Carpetas de usuario y aplicaciones por defecto")"
if command -v xdg-user-dirs-update >/dev/null; then
    run xdg-user-dirs-update
    if [[ -f "$CFG/user-dirs.dirs" ]]; then
        folders=$(sed -n 's/^XDG_[A-Z]*_DIR="\$HOME\/\(.\+\)"$/\1/p' "$CFG/user-dirs.dirs" | paste -sd' ' -)
        echo "    $(L "user folders" "carpetas de usuario"): $folders"
    fi
fi

if [[ -f /usr/share/applications/thunar.desktop ]] && command -v xdg-mime >/dev/null; then
    run xdg-mime default thunar.desktop inode/directory
    echo "    $(L "default file manager" "gestor de archivos por defecto"): Thunar"
fi

if command -v xdg-settings >/dev/null; then
    for desktop in brave-browser.desktop brave.desktop; do
        if [[ -f "/usr/share/applications/$desktop" ]]; then
            run xdg-settings set default-web-browser "$desktop" 2>/dev/null || true
            echo "    $(L "default browser" "navegador por defecto"): Brave ($desktop)"
            break
        fi
    done
fi

# Ensure GTK / portal / Electron apps honor dark mode consistently
if command -v gsettings >/dev/null; then
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    run gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    echo "    $(L "GTK dark mode" "modo oscuro GTK"): Adwaita-dark + Papirus-Dark"
fi

if systemctl list-unit-files bluetooth.service >/dev/null 2>&1 &&
   [[ "$(systemctl is-enabled bluetooth.service 2>/dev/null)" != enabled ]]; then
    step "$(L "Enabling Bluetooth service" "Activando servicio de Bluetooth")"
    if ! can_sudo; then
        warn "bluetooth.service $NO_SUDO_MSG"
    else
        run sudo systemctl enable --now bluetooth.service ||
            warn "$(L "could not enable bluetooth.service" "no se pudo activar bluetooth.service")"
    fi
fi

# --- 5. Initialize Nitrogen, Pywal & i3 runtime state ---
step "$(L "Initializing Nitrogen and Pywal" "Inicializando Nitrogen y Pywal")"
INITIAL_WALL="${WALLPAPER_ARG:-$(nitrogen_current_wallpaper)}"
[[ -f "$INITIAL_WALL" ]] || INITIAL_WALL="$DEFAULT_WALLPAPER"

run mkdir -p "$CFG/nitrogen" "$DOTS_CACHE" "$WAL_CACHE"

if (( DRY_RUN )); then
    echo "    [dry-run] configure Nitrogen with $(short "$INITIAL_WALL")"
    echo "    [dry-run] dots-pywal --image $(short "$INITIAL_WALL")"
else
    # Point Nitrogen browser at repo wallpapers (plus user Pictures/Wallpapers if present)
    wall_dirs="$REPO/wallpapers;"
    [[ -d "$HOME/Pictures/Wallpapers" ]] && wall_dirs+="$HOME/Pictures/Wallpapers;"
    [[ -d "$HOME/Imágenes/Wallpapers" ]] && wall_dirs+="$HOME/Imágenes/Wallpapers;"
    if [[ ! -f "$CFG/nitrogen/nitrogen.cfg" ]]; then
        cat >"$CFG/nitrogen/nitrogen.cfg" <<EOF
[geometry]
posx=200
posy=120
sizex=820
sizey=560

[nitrogen]
view=icon
recurse=true
sort=alpha
icon_caps=false
dirs=$wall_dirs
EOF
    fi

    if [[ ! -f "$CFG/nitrogen/bg-saved.cfg" || -n "$WALLPAPER_ARG" ]]; then
        cat >"$CFG/nitrogen/bg-saved.cfg" <<EOF
[xin_-1]
file=$INITIAL_WALL
mode=5
bgcolor=#000000
EOF
    fi

    # Ensure outputs.conf exists so i3 -C validates cleanly before first X11 login
    if [[ ! -f "$DOTS_CACHE/outputs.conf" ]]; then
        echo "# Generated automatically on i3 start by dots-monitors" >"$DOTS_CACHE/outputs.conf"
    fi

    ensure_wal_fallbacks
    "$REPO/scripts/dots-pywal" --image "$INITIAL_WALL"
    echo "    $(L "wallpaper & Pywal ready" "wallpaper y Pywal listos"): $(short "$INITIAL_WALL")"
fi

# --- 6. Verify i3 configuration syntax ---
if command -v i3 >/dev/null && (( ! DRY_RUN )); then
    step "$(L "Verifying i3 configuration" "Verificando la configuración de i3")"
    if i3 -C -c "$CFG/i3/config" >/dev/null 2>&1; then
        echo "    config ok"
    else
        warn "$(L "i3 reported syntax issues:" "i3 reportó problemas de sintaxis:")"
        i3 -C -c "$CFG/i3/config" 2>&1 | sed 's/^/      /' || true
    fi
fi

echo
step "$(L "Done" "Listo")"
[[ -d "$BACKUP" ]] && echo "  $(L "Previous files backed up in" "Tus archivos anteriores quedaron en") $(short "$BACKUP")"
case ":$PATH:" in
    *":$BIN:"*) ;;
    *) [[ "$login_shell" == */zsh ]] || warn "$(short "$BIN") $(L "is not in your PATH (keybinds still work; add it to run dots-* commands from a terminal)" "no está en tu PATH (los atajos funcionan igual; agrégalo para ejecutar dots-* en terminal)")" ;;
esac
if [[ -n "${I3SOCK:-}" ]]; then
    echo "  $(L "You are inside i3. Reload with: Super + Shift + R (or i3-msg restart)." "Estás dentro de i3. Recarga con: Super + Shift + R (o i3-msg restart).")"
else
    echo "  $(L "Log in to i3 (X11) to use your new setup." "Inicia sesión en i3 (X11) para usar tu nueva configuración.")"
fi
