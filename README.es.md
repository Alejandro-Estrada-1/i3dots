# i3dots — Arch Linux i3 + Polybar + Nitrogen + Pywal

*[Read in English](README.md)*

Dotfiles minimalistas estilo *frosted glass* para **Arch Linux** con **i3 (X11)**, barra inferior flotante de 3 islas en **Polybar**, gestión de fondos con **Nitrogen**, paleta dinámica automática con **Pywal**, desenfoque `dual_kawase` con **Picom**, **Kitty + Zsh (Oh My Zsh + Powerlevel10k)**, **Brave** como navegador predeterminado, configuración automática **multi-monitor HDMI** y **centro multimedia flotante** para X11.

---

## Stack

| Componente | Herramienta |
|---|---|
| Gestor de ventanas | `i3-wm` (bordes rectos de 2px con Pywal, gaps 8px internos / 6px externos) |
| Barra de estado | `polybar` (3 islas inferiores flotantes: escritorios, título activo y estado) |
| Fondos de pantalla | `nitrogen` (restauración multi-monitor + selector GUI sincronizado con Pywal) |
| Paleta dinámica | `pywal` (plantillas en vivo para Polybar, i3, Kitty, Rofi, Dunst, Cava, `dots-media`, `i3lock-color`) |
| Compositor | `picom` (GLX + blur `dual_kawase`, esquinas rectas de `0px` en ventanas) |
| Terminal y Shell | `kitty` + `zsh` (Oh My Zsh, Powerlevel10k, `zoxide`, `atuin`, `fastfetch`) |
| Menú y notificaciones | `rofi` + `dunst` |
| Navegador | `brave` (`brave-bin` se instala automáticamente si no existe) |
| Centro multimedia | `dots-media` (panel flotante GTK3 + Playerctl con carátula y pestañas por reproductor) |

---

## Instalación (Arch Linux)

```bash
git clone https://github.com/Alejandro-Estrada-1/i3dots.git
cd i3dots
./install.sh
```

### Opciones del instalador

| Opción | Descripción |
|---|---|
| `--no-packages` | Omite la instalación con `pacman` / AUR; solo enlaza configuraciones e inicializa Nitrogen + Pywal |
| `--lang en\|es` | Idioma de menús, panel multimedia y visor de atajos |
| `--kb-layout <dist>` | Distribución de teclado X11, ej. `us`, `latam`, `"latam,us"` |
| `--kb-variant <var>` | Variante opcional de teclado (ej. `intl`) |
| `--kb-options <opts>` | Opciones XKB (por defecto `grp:ctrl_space_toggle` con varias distribuciones) |
| `--wallpaper <ruta>` | Fondo inicial para Nitrogen + Pywal |
| `--dry-run` | Muestra qué haría sin realizar cambios |
| `-y`, `--yes` | Instalación desatendida (`--noconfirm`) |

Cualquier archivo previo en `~/.config` se respalda automáticamente en `~/.config/i3dots-backup-<fecha>/` antes de crear los enlaces simbólicos.

---

## Atajos de teclado

### Programas y utilidades

| Atajo | Acción |
|---|---|
| `Super + B` | Abrir navegador **Brave** |
| `Super + V` | Historial del portapapeles en **Rofi** (`dots-clipboard` / `greenclip`) |
| `Alt + Enter` | Abrir terminal **Kitty** |
| `Super + E` | Abrir gestor de archivos (**Thunar**) |
| `Alt + X` | Abrir menú de aplicaciones (**Rofi**) |
| `Alt + Z` | Abrir menú de energía (`dots-powermenu`) |
| `Super + P` | Abrir/cerrar **Centro multimedia** (`dots-media`) |
| `Super + N` / `Super + Shift + N` | Historial de notificaciones / cerrar notificaciones |
| `Alt + W` | Cambiar fondo (**Nitrogen** + sincronización automática con **Pywal**) |
| `Alt + C` | Abrir menú de **Pywal** (recargar, aleatorio, modo claro/oscuro, backends) |
| `Super + Shift + K` | Visor interactivo de atajos |
| `Super + L` | Bloquear pantalla (`i3lock-color` con colores Pywal) |
| `Super + K` / `Super + J` | Ocultar / mostrar Polybar (ajusta automáticamente el espacio inferior) |
| `Super + Shift + R` | Actualizar disposición de monitores HDMI y recargar i3 |
| `Print` | Captura de pantalla (`flameshot gui -c`) |
| `XF86Calculator` | Calculadora (`kcalc`) |

### Ventanas, foco y escritorios

| Atajo | Acción |
|---|---|
| `Alt + Q` | Cerrar ventana activa |
| `Super + M` | Salir de i3 |
| `Super + F` | Pantalla completa |
| `Alt + F` | Alternar ventana flotante |
| `Alt + S` | Alternar división |
| `Super + R` | Modo redimensionar con teclado (`A/D/W/S` o flechas, `Shift` para saltos grandes) |
| `Super + Shift + -` / `Super + -` | Enviar ventana al scratchpad / mostrar u ocultar scratchpad |
| `Super + A / D / W / S` | Foco izquierda / derecha / arriba / abajo |
| `Super + Shift + A / D / W / S` | Mover ventana izquierda / derecha / arriba / abajo |
| `Super + Clic izq. / der.` | Mover / redimensionar ventana flotante |
| `Alt + 1..5` | Ir al escritorio `1..5` (laptop) |
| `Ctrl + 1..5` | Ir al escritorio `6..10` (monitor HDMI) |
| `Super + 1..5` | Mover ventana al escritorio `1..5` |
| `Ctrl + Shift + 1..5` | Mover ventana al escritorio `6..10` |
| `Super + Rueda abajo / arriba` | Escritorio siguiente / anterior |
| `Super + ,` / `Super + .` | Foco al monitor izquierdo / derecho |
| `Super + Shift + ,` / `.` | Mover ventana al monitor izquierdo / derecho |

### Teclas multimedia y brillo

El volumen (`±5%`, máx. `150%`) y brillo (`±2%`) pasan por `dots-mediakey` con *debounce* de 50 ms mediante `flock` y notificaciones OSD minimalistas con barra de progreso en Dunst. Las teclas de reproducción controlan reproductores MPRIS con `playerctl`.

---

## Multi-monitor (Laptop + HDMI externo)

`dots-monitors` detecta automáticamente las salidas X11 con `xrandr` (y `dots-monitor-watch` escucha eventos DRM del kernel con `udevadm` para hotplug automático al conectar/desconectar HDMI):
- Coloca la pantalla de laptop (`eDP-*` / `LVDS-*`) a la izquierda (`0x0`) con su tasa de refresco más alta.
- Coloca el monitor externo `HDMI-*` a la derecha con su resolución preferida.
- Asigna los escritorios `1–5` a la laptop y `6–10` al monitor HDMI (con *fallback* automático a la laptop al desconectarlo).
- Restaura el fondo con Nitrogen en todas las pantallas y reinicia las 3 islas de Polybar en cada monitor.

También puedes forzar la actualización manualmente en cualquier momento con `Super + Shift + R` (`dots-monitors --reload`).

---

## Flujo Nitrogen + Pywal

Pulsa `Alt + W` para abrir **Nitrogen**, elige tu fondo, pulsa **Apply** y cierra la ventana: `dots-wallpaper` ejecuta automáticamente `dots-pywal` (`wal -n`) y actualiza al instante los bordes de i3, Polybar, Kitty, Rofi, Dunst, Cava, `dots-media` y `i3lock-color`.
