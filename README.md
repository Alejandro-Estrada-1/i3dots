# i3dots — Arch Linux i3 + Polybar + Nitrogen + Pywal

*[Leer en español](README.es.md)*

Minimalist frosted-glass **i3 (X11)** dotfiles for **Arch Linux** featuring a 3-island floating bottom **Polybar**, **Nitrogen** wallpaper management, full **Pywal** dynamic color synchronization, **Picom** dual-kawase blur, **Kitty + Zsh (Oh My Zsh + Powerlevel10k)**, **Brave** as default browser, automatic **multi-monitor HDMI** layout, and a floating **X11 MPRIS media center**.

---

## Stack

| Component | Tool |
|---|---|
| Window Manager | `i3-wm` (sharp 2px Pywal borders, 8px inner / 6px outer gaps) |
| Status Bar | `polybar` (3 floating bottom islands: workspaces + live `cava` audio visualizer, active title, system status) |
| Wallpaper | `nitrogen` (multi-monitor restore + GUI picker synced with Pywal) |
| Dynamic Palette | `pywal` (live templates for Polybar, i3, Kitty, Rofi, Dunst, Cava, `dots-media`, `i3lock-color`) |
| Compositor | `picom` (GLX + `dual_kawase` frosted blur, crisp 0px window corners) |
| Terminal & Shell | `kitty` + `zsh` (Oh My Zsh, Powerlevel10k, `zoxide`, `atuin`, `fastfetch`) |
| Launcher & Notifications | `rofi` + `dunst` |
| Browser | `brave` (`brave-bin` installed automatically if missing) |
| Media Center | `dots-media` (GTK3 + Playerctl floating X11 panel with album art & multi-player tabs) |

---

## Installation (Arch Linux)

```bash
git clone https://github.com/Alejandro-Estrada-1/i3dots.git
cd i3dots
./install.sh
```

### Installer options

| Flag | Description |
|---|---|
| `--no-packages` | Skip `pacman` / AUR package installation; only link configs and initialize Nitrogen + Pywal |
| `--lang en\|es` | Choose interface language for menus, media panel and keybinds cheatsheet |
| `--kb-layout <layout>` | X11 keyboard layout(s), e.g. `us`, `latam`, `"latam,us"` |
| `--kb-variant <variant>` | Optional XKB variant (e.g. `intl`) |
| `--kb-options <opts>` | Optional XKB options (defaults to `grp:ctrl_space_toggle` for multi-layout) |
| `--wallpaper <path>` | Initial wallpaper for Nitrogen + Pywal |
| `--dry-run` | Preview all actions without modifying anything |
| `-y`, `--yes` | Unattended install (`--noconfirm`) |

Any existing config in `~/.config` is automatically backed up to `~/.config/i3dots-backup-<timestamp>/` before symlinking.

---

## Keybindings

### Programs & Utilities

| Shortcut | Action |
|---|---|
| `Super + B` | Open **Brave** browser |
| `Super + V` | Clipboard history in **Rofi** (`dots-clipboard` / `greenclip`) |
| `Alt + Enter` | Open **Kitty** terminal |
| `Super + E` | Open file manager (**Thunar**) |
| `Alt + X` | Open application launcher (**Rofi**) |
| `Alt + Z` | Open power menu (`dots-powermenu`) |
| `Super + P` | Toggle **Media Center** (`dots-media`) |
| `Super + N` / `Super + Shift + N` | Show notification history / close notifications |
| `Alt + W` | Change wallpaper (**Nitrogen** + automatic **Pywal** sync) |
| `Alt + C` | Open **Pywal** theme & backend menu |
| `Super + Shift + K` | Interactive keybinds cheatsheet |
| `Super + L` | Lock screen (`i3lock-color` with Pywal colors) |
| `Super + K` / `Super + J` | Hide / show floating bottom Polybar (dynamically adjusts bottom gap) |
| `Super + Shift + R` | Refresh HDMI monitor layout and reload i3 |
| `Print` | Screenshot (`flameshot gui -c`) |
| `XF86Calculator` | Calculator (`kcalc`) |

### Windows, Focus & Workspaces

| Shortcut | Action |
|---|---|
| `Alt + Q` | Close focused window |
| `Super + M` | Exit i3 |
| `Super + F` | Toggle fullscreen |
| `Alt + F` | Toggle floating |
| `Alt + S` | Toggle split layout |
| `Super + R` | Keyboard resize mode (`A/D/W/S` or arrows, `Shift` for larger steps) |
| `Super + Shift + Tab` / `Super + Tab` | Move window to scratchpad / toggle scratchpad |
| `Super + A / D / W / S` | Focus left / right / up / down |
| `Super + Shift + A / D / W / S` | Move window left / right / up / down |
| `Super + Left / Right click` | Drag / resize floating window |
| `Alt + 1..5` | Go to workspace `1..5` (laptop) |
| `Ctrl + 1..5` | Go to workspace `6..10` (external HDMI) |
| `Super + 1..5` | Move window to workspace `1..5` |
| `Ctrl + Shift + 1..5` | Move window to workspace `6..10` |
| `Super + Scroll down / up` | Next / previous workspace |
| `Super + ,` / `Super + .` | Focus left / right monitor |
| `Super + Shift + ,` / `.` | Move window to left / right monitor |

### Hardware & Media Keys

Volume (`±5%`, max `150%`) and brightness (`±2%`) are handled through `dots-mediakey`. Keyboards without media keys can use **`Super + +` / `Super + -`** for volume and **`Alt + +` / `Alt + -`** for brightness (numpad `+`/`-` work too). On machines without a hardware backlight (desktops / external monitors), brightness falls back to software dimming with `xrandr --brightness` (`±5%`, 20–100%). Everything goes through `dots-mediakey` with a 50 ms `flock` debounce and Pywal-styled Dunst OSD progress bars. Playback keys (`XF86AudioPlay/Pause/Next/Prev`) control MPRIS players via `playerctl`.

---

## Multi-Monitor (Laptop + External HDMI)

`dots-monitors` automatically detects connected X11 outputs via `xrandr` (and `dots-monitor-watch` listens to kernel DRM uevents via `udevadm` for automatic HDMI hotplug):
- Places the internal laptop display (`eDP-*` / `LVDS-*`) on the left at `0x0` using its highest refresh rate.
- Places any connected `HDMI-*` (or other external) display to the right at its preferred resolution.
- Binds workspaces `1–5` to the laptop and `6–10` to the external HDMI monitor (with seamless fallback to the laptop when unplugged).
- Restores the Nitrogen wallpaper across all displays and relaunches all 3 Polybar islands per monitor.

You can also force a refresh manually anytime with `Super + Shift + R` (`dots-monitors --reload`).

---

## Nitrogen + Pywal Workflow

Press `Alt + W` to open **Nitrogen**, select your wallpaper, click **Apply**, and close Nitrogen — `dots-wallpaper` automatically invokes `dots-pywal` (`wal -n`), updating i3 borders, Polybar, Kitty, Rofi, Dunst, Cava, `dots-media`, and `i3lock-color` in real time without dirtying the repository.
