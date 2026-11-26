# AGENTS.md — Arch Linux i3 Dotfiles (`i3dots`)

Este archivo define las reglas obligatorias del proyecto. **Léelo siempre antes de crear o modificar archivos**, cumple estrictamente cada punto y actualízalo cuando el usuario agregue nuevos requisitos o especificaciones visuales.

---

## 1. Objetivo del proyecto
Crear un repositorio completo de dotfiles para **Arch Linux** usando **i3 (X11)** con un instalador automatizado en Bash (`install.sh`) y subirlo a GitHub (`Alejandro-Estrada-1`).

### Stack principal obligatorio
- **SO:** Arch Linux (y derivadas con `pacman` + AUR helper `yay`/`paru`).
- **Window Manager:** `i3` (`i3-wm`, X11).
- **Barra de estado:** `polybar`.
- **Gestor de fondos de pantalla:** `nitrogen`.
- **Paleta de colores dinámica:** `pywal` (sincronizando colores del wallpaper activo en i3, Polybar, terminal, rofi, notificaciones, centro multimedia, etc.).
- **Navegador por defecto:** **Brave** (`brave-bin` vía AUR si no está instalado).

---

## 2. Regla estricta de diseño visual
- **Respetar en todo momento el diseño mostrado en las imágenes de referencia del usuario.**
- **NO** copiar la estética, temas Catppuccin/misc ni estilos visuales de `/home/ale/Documentos/Detodounpoco/dotfiles` (versión Hyprland). De ese repositorio **únicamente** se heredan:
  1. Los atajos de teclado.
  2. La configuración multi-monitor (laptop + HDMI externo).
  3. El centro multimedia (`dots-media`).
  4. La estructura/ergonomía base del instalador automatizado (`install.sh`).

### Especificación visual (extraída de las 4 imágenes de referencia)
Diseño minimalista, limpio y atmosférico tipo *frosted glass* oscuro con paleta dinámica generada por **Pywal** desde el wallpaper (referencia base: lago alpino con pinos y montañas nevadas en tonos verde-petróleo/pizarra oscuros y acentos gris-salvia claros):

- **Polybar (barra inferior flotante de 3 islas independientes por monitor):**
  - Posición: **abajo** (`bottom = true`), `offset-y = 6`, `height = 26`, `override-redirect = true`, `wm-restack = i3`.
  - Geometría exacta de las 3 islas:
    - `bar/left`: `width = 25%`, `offset-x = 1%` — icono de cubo (``) + separador `|` + workspaces dinámicos de i3 (`󰄰 1 | 󰄰 2 | ... | 󰄯 4` con círculo hueco para inactivos, círculo sólido + subrayado inferior de `2px` en color claro para el activo, `pin-workspaces = true` para multi-monitor) + visualizador de audio `cava` (`| ▁▂▃▄▅▆▇█`, `dots-cava` heredado de Waybar adaptado a Polybar) alineado a la derecha de la isla con el color acento de Pywal.
    - `bar/center`: `width = 25%`, `offset-x = 37.5%` — título de la ventana activa (`xwindow`) centrado; cuando no hay ventana enfocada se mantiene el marco translúcido vacío.
    - `bar/right`: `width = 25%`, `offset-x = 74%` — módulos centrados separados por `|`: botón de centro multimedia (`󰝚`), volumen (` 69%`), reloj (` 08:51`), batería (`󰄯 Full - 100%`), Wi-Fi (``), Bluetooth (``).
  - Estilo de las 3 islas: fondo oscuro translúcido Pywal (`#d9<background>`, con blur de `picom`), **borde fino de `1px`** (`border-size = 1`, color claro/muted de Pywal), esquinas ligeramente redondeadas (`radius = 3`), tipografía `JetBrainsMono Nerd Font`.
  - **Regla técnica Polybar:** Polybar solo expande `${colors.x}` cuando es el valor completo; **nunca** incrustarlo en etiquetas inline (`%{F${colors.x}}` imprime `}}` literal). Colorear con `format-*-foreground` / `label-*-foreground` y usar `%{F-}` para volver al color base. Módulos dependientes de hardware (batería, Wi-Fi, Bluetooth) solo se cargan si el dispositivo existe, y toda llamada a `bluetoothctl` va con `timeout`.
  - **Regla técnica Kitty:** `globinclude` no acepta rutas absolutas ni `~`; los colores de Pywal se cargan con `include ${HOME}/.cache/wal/kitty-colors.conf`.
- **i3 (ventanas, bordes y gaps):**
  - Bordes finos y limpios: `default_border pixel 2`, `default_floating_border pixel 2`.
  - **Sin esquinas redondeadas en ventanas** (`corner-radius = 0` en picom), manteniendo marcos rectos y nítidos como en las capturas.
  - Gaps: `gaps inner 8`, `gaps outer 6`, `gaps bottom 36` (reservando espacio limpio para la Polybar inferior flotante y ajustándose dinámicamente al ocultar/mostrar la barra con `SUPER + K` / `SUPER + J`).
  - Colores de borde vía Xresources de Pywal (`set_from_resource`): borde enfocado claro (`color7`/`foreground`), desenfocado sutil (`color8`), urgente (`color1`).
- **Compositor (`picom`):**
  - Backend `glx` con `vsync = true`.
  - **Dual-kawase blur** (`blur-method = "dual_kawase"`, `blur-strength = 7`) detrás de ventanas con transparencia RGBA (`kitty`, `polybar`, `rofi`, `dunst`, `dots-media`), manteniendo nítidos y opacos los navegadores y apps como Brave/Spotify.
  - `corner-radius = 0`, transiciones/fading suaves, sin sombras pesadas.
- **Terminal y shell (`kitty` + `zsh`):**
  - Mantener `kitty` + `zsh` (Oh My Zsh + Powerlevel10k + `zoxide` + `atuin` + `fastfetch` limpio para Arch/i3).
  - Kitty translúcida (`background_opacity 0.70`) con blur `dual_kawase` de `picom` para replicar el efecto vidrio esmerilado visto en los paneles de `tty-clock` y `cava`.
  - Colores de Kitty, `cava`, `rofi`, `dunst`, `dots-media` y `i3lock-color` sincronizados automáticamente mediante plantillas de Pywal (`~/.config/wal/templates/`).
- **Launcher (`rofi`), notificaciones (`dunst`), lockscreen (`i3lock-color`) y centro multimedia (`dots-media`):**
  - Todos siguen la misma gramática visual de las islas de Polybar: fondo oscuro translúcido con blur, borde fino `1px` en color Pywal, `radius = 3px`, fuente `JetBrainsMono Nerd Font`.
- **Integración `nitrogen` + `pywal`:**
  - `nitrogen` gestiona el fondo en todos los monitores; `pywal` se ejecuta con `-n` (sin pisar a Nitrogen) y regenera todas las plantillas + Xresources + recarga en vivo de i3, Polybar, Kitty, Dunst y Cava.
  - Wallpapers incluidos en `wallpapers/`: `mountain-lake.jpg` (por defecto, lago alpino), `misty-pines.jpg`, `arctic-dusk.jpg` y `amber-dusk.jpg`.
- **Ergonomía y acabados adicionales de X11 / i3:**
  - Arranque secuencial en i3 (`dots-monitors --init && dots-pywal --restore`) + `flock` en `dots-polybar` para evitar *race conditions* o barras duplicadas.
  - Tema GTK oscuro coherente (`config/gtk-3.0/settings.ini`, `config/gtk-4.0/settings.ini` con `Adwaita-dark` + `Papirus-Dark` + `gsettings`).
  - Tap-to-click y *disable-while-typing* para touchpad en `dots-input` (`libinput` vía `xinput`).
  - Soporte para `startx` (`home/.xinitrc` + `xorg-server`/`xorg-xinit` en `packages/pacman.txt`).
  - Notificaciones OSD de volumen y brillo vía `dunstify` con barra de progreso en `dots-mediakey`.
  - Modo de redimensionado por teclado (`Super + R`), *scratchpad* (`Super + Tab` / `Super + Shift + Tab`), hotplug automático HDMI sin dependencias extra (`dots-monitor-watch` vía `udevadm`) e historial del portapapeles con Rofi (`Super + V` → `dots-clipboard` con `greenclip`).

---

## 3. Características heredadas de `/home/ale/Documentos/Detodounpoco/dotfiles`

### 3.1 Atajos de teclado (adaptados de `config/hypr/modules/keybinds.lua` a i3)
Todos los atajos deben mantenerse equivalentes en i3 (`Mod4` = `SUPER`, `Mod1` = `ALT`):

#### Programas y utilidades
| Atajo | Acción | Comando / Nota |
|---|---|---|
| `SUPER + B` | Abrir navegador **Brave** | `brave` (obligatorio) |
| `ALT + Return` | Abrir terminal | Terminal del rice |
| `SUPER + E` | Abrir gestor de archivos | `thunar` |
| `ALT + X` | Abrir menú de aplicaciones | `rofi -show drun` |
| `ALT + Z` | Abrir menú de energía | `~/.local/bin/dots-powermenu` (adaptado a i3/X11) |
| `SUPER + P` | Abrir/cerrar centro multimedia | `~/.local/bin/dots-media` (adaptado a X11/i3) |
| `SUPER + N` | Panel / centro de notificaciones | Notificador X11 del rice |
| `ALT + C` | Cambiar tema / recargar colores Pywal | Script de colores/pywal |
| `ALT + W` | Cambiar fondo de pantalla | Nitrogen + actualización automática de Pywal |
| `XF86Calculator` | Abrir calculadora | `kcalc` |
| `Print` | Captura de pantalla | `flameshot gui -c` |
| `SUPER + L` | Bloquear pantalla | Bloqueador X11 (p. ej. `i3lock-color`) |
| `SUPER + K` | Cerrar la barra | `pkill -x polybar` |
| `SUPER + J` | Abrir la barra | Lanzador de `polybar` (en todos los monitores) |

#### Gestión de ventanas
| Atajo | Acción |
|---|---|
| `ALT + Q` | Cerrar ventana activa (`kill`) |
| `SUPER + M` | Salir de i3 (`exit`) |
| `SUPER + F` | Pantalla completa (`fullscreen toggle`) |
| `ALT + F` | Alternar ventana flotante (`floating toggle`) |
| `ALT + S` | Alternar división (`layout toggle split`) |
| `SUPER + Clic izq.` | Mover ventana flotante (`floating_modifier Mod4`) |
| `SUPER + Clic der.` | Redimensionar ventana |

#### Foco (WASD)
| Atajo | Acción |
|---|---|
| `SUPER + A` | Foco a la izquierda (`focus left`) |
| `SUPER + D` | Foco a la derecha (`focus right`) |
| `SUPER + W` | Foco arriba (`focus up`) |
| `SUPER + S` | Foco abajo (`focus down`) |

#### Workspaces (1–5 laptop, 6–10 HDMI externo)
| Atajo | Acción |
|---|---|
| `ALT + 1..5` | Ir al workspace `1..5` |
| `CTRL + 1..5` | Ir al workspace `6..10` |
| `SUPER + 1..5` | Mover ventana al workspace `1..5` |
| `CTRL + SHIFT + 1..5` | Mover ventana al workspace `6..10` |
| `SUPER + Rueda abajo / arriba` | Workspace siguiente / anterior |

#### Monitores (laptop a la izquierda, HDMI externo a la derecha)
| Atajo | Acción |
|---|---|
| `SUPER + ,` (`comma`) | Foco al monitor izquierdo (`focus output left`) |
| `SUPER + .` (`period`) | Foco al monitor derecho (`focus output right`) |
| `SUPER + SHIFT + ,` | Mover ventana al monitor izquierdo (`move container to output left`) |
| `SUPER + SHIFT + .` | Mover ventana al monitor derecho (`move container to output right`) |

#### Teclas multimedia y brillo (con debounce `dots-mediakey`)
- Mantener `dots-mediakey` con `flock` (ventana de 50 ms) para evitar eventos duplicados en laptops (WMI):
  - `XF86AudioRaiseVolume`: +5% (máx 150%, `wpctl`)
  - `XF86AudioLowerVolume`: -5% (`wpctl`)
  - Alternativas para teclados sin teclas multimedia: `SUPER + +` / `SUPER + -` (volumen ±5%) y `ALT + +` / `ALT + -` (brillo), incluyendo `equal` y `KP_Add`/`KP_Subtract`.
  - `XF86AudioMute`: toggle mute audio (`wpctl`)
  - `XF86AudioMicMute`: toggle mute micrófono (`wpctl`)
  - `XF86MonBrightnessUp` / `XF86MonBrightnessDown`: +/- 2% (`brightnessctl`); sin backlight por hardware (PC de escritorio) se usa brillo por software `xrandr --brightness` (±5%, 20–100%).
  - `XF86AudioNext`, `XF86AudioPause`, `XF86AudioPlay`, `XF86AudioPrev`: `playerctl`

---

### 3.2 Configuración multi-monitor HDMI (adaptada de `config/hypr/modules/monitors.lua` a X11/`xrandr`)
- Pantalla interna de laptop (`eDP-1` o salida interna detectada dinámicamente por `xrandr`) a la izquierda (`0x0`), a su mayor tasa de refresco / modo preferido.
- Monitor externo HDMI (`HDMI-1`, `HDMI-1-0`, `HDMI-A-1`, etc., detectado automáticamente con `xrandr`) posicionado a la derecha (`--right-of`) con su resolución preferida (`--auto`).
- Soporte para cualquier otro monitor externo conectado y desconexión limpia (script dedicado ejecutado en autostart y en recarga/hotplug).
- Al aplicar cambios de monitores:
  1. Aplicar disposición con `xrandr`.
  2. Restaurar fondo en todas las pantallas con `nitrogen --restore`.
  3. Reiniciar `polybar` en cada monitor conectado.
- Asignación de workspaces en i3:
  - Workspaces `1` a `5` asignados al monitor principal (laptop).
  - Workspaces `6` a `10` asignados al monitor HDMI externo (con fallback automático al monitor de laptop si el HDMI no está conectado).

---

### 3.3 Centro multimedia (`dots-media`)
- Adaptar `scripts/dots-media` (Python + GTK + `Playerctl`) de Wayland (`gtk4-layer-shell`) a **X11 / i3**:
  - Ventana flotante sin bordes/decoración, posicionada bajo la barra (esquina superior derecha del monitor activo), por encima de las ventanas.
  - Toggle por D-Bus (ejecutar de nuevo cierra el panel), también se cierra con `Esc` o al perder foco / hacer clic fuera.
  - Pestañas por reproductor MPRIS activo cuando hay más de uno.
  - Carátula cuadrada (con descarga en caché y placeholder si no hay), título, artista, fuente/reproductor, barra de progreso + tiempos y botones Anterior / Reproducir-Pausar / Siguiente.
  - Regla de ventana en i3 (`for_window [class="..."] floating enable, sticky enable, border none`) para garantizar comportamiento limpio en X11.
  - Colores sincronizados dinámicamente con **Pywal** y respetando el estilo visual de las imágenes.

---

## 4. Instalador automatizado (`install.sh`)
- Script Bash (`#!/usr/bin/env bash`, `set -euo pipefail`) pensado para **Arch Linux**.
- Debe soportar banderas útiles similares al repo original: `--no-packages`, `--dry-run`, `-y/--yes`, `--lang (en|es)`, `--kb-layout`, `--kb-variant`, `--kb-options`, `-h/--help`.
- **Instalación automática de Brave:** verificar si `brave` existe (`command -v brave` / `pacman -Qi brave-bin`); si no está instalado, instalar `brave-bin` mediante AUR (`yay` o `paru`, instalando `yay-bin` automáticamente si no hay AUR helper).
- Instalar todos los paquetes oficiales (`packages/pacman.txt`) y AUR (`packages/aur.txt`) faltantes sin reinstalar lo ya presente (`--needed`).
- Respaldar configuraciones existentes en `~/.config/i3dots-backup-<fecha>/` antes de crear symlinks hacia el repo.
- Enlazar configuraciones en `~/.config/` y scripts en `~/.local/bin/`.
- Configurar distribución de teclado en X11 (`setxkbmap` / configuración persistente), carpetas de usuario (`xdg-user-dirs-update`), gestor de archivos por defecto (`thunar`) y servicios necesarios (p. ej. `bluetooth.service`).
- Inicializar `nitrogen` + `pywal` con el wallpaper por defecto del rice para que los archivos de color existan desde el primer inicio.
- Validar sintaxis de la configuración de i3 (`i3 -C`) y de todos los scripts Bash (`bash -n`).

---

## 5. Control de versiones y entrega en GitHub
- Inicializar repositorio Git en `/home/ale/Documentos/Detodounpoco/i3dots` con rama principal `main`, `.gitignore` limpio y `README.md` (y opcionalmente `README.es.md`) documentando instalación, atajos y dependencias.
- Verificar configuraciones y scripts antes de hacer commit.
- Subir a GitHub bajo la cuenta configurada (`Alejandro-Estrada-1`) creando el repositorio remoto con `gh` una vez validado todo.
