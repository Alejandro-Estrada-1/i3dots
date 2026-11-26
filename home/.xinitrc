#!/bin/sh
# X11 startup script for launching i3dots via `startx` from a TTY.
# Display managers (SDDM, LightDM, Ly, GDM) use /usr/share/xsessions/i3.desktop.

userresources="$HOME/.Xresources"
usermodmap="$HOME/.Xmodmap"
sysresources="/etc/X11/xinit/.Xresources"
sysmodmap="/etc/X11/xinit/.Xmodmap"

[ -f "$sysresources" ]  && xrdb -merge "$sysresources"
[ -f "$sysmodmap" ]     && xmodmap "$sysmodmap"
[ -f "$userresources" ] && xrdb -merge "$userresources"
[ -f "$usermodmap" ]    && xmodmap "$usermodmap"
[ -f "${XDG_CACHE_HOME:-$HOME/.cache}/wal/colors.Xresources" ] && \
    xrdb -merge "${XDG_CACHE_HOME:-$HOME/.cache}/wal/colors.Xresources"

if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

export XDG_CURRENT_DESKTOP=i3
export XDG_SESSION_TYPE=x11
export GTK_THEME=Adwaita:dark

exec i3
