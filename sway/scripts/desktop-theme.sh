#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO // DESKTOP APPEARANCE SYNC (GTK, icons, cursor, fonts)
# ==============================================================================
# Applies the desktop-chrome half of the design system to every toolkit that
# reads it, and resolves the cursor theme against what is ACTUALLY installed.
#
# Why this exists as a script rather than plain `gsettings` lines in the sway
# config: sway has no conditionals, so a hardcoded cursor theme leaves a fresh
# install with no cursor at all when that theme is missing. See PALETTE.md.
# ==============================================================================
set -uo pipefail

GTK_THEME_PREF=(catppuccin-mocha-blue-standard+default Catppuccin-Mocha-Standard-Blue-Dark Adwaita-dark)
ICON_THEME_PREF=(Papirus-Dark Papirus Adwaita)
CURSOR_THEME_PREF=(Bibata-Modern-Ice Bibata-Modern-Classic Adwaita default)
CURSOR_SIZE=24
UI_FONT="JetBrainsMono Nerd Font 10"

# Return the first candidate that exists in any standard theme search path.
_first_installed() {
    local kind="$1"; shift
    local dirs=()
    case "$kind" in
        icons)  dirs=("$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons) ;;
        themes) dirs=("$HOME/.local/share/themes" "$HOME/.themes" /usr/share/themes) ;;
    esac
    local cand dir
    for cand in "$@"; do
        for dir in "${dirs[@]}"; do
            [[ -d "$dir/$cand" ]] && { printf '%s\n' "$cand"; return 0; }
        done
    done
    return 1
}

GTK_THEME=$(_first_installed themes "${GTK_THEME_PREF[@]}") || GTK_THEME="Adwaita-dark"
ICON_THEME=$(_first_installed icons  "${ICON_THEME_PREF[@]}")  || ICON_THEME="Adwaita"
# A cursor theme is an icon-theme dir that actually carries a cursors/ subdir.
CURSOR_THEME=""
for cand in "${CURSOR_THEME_PREF[@]}"; do
    for dir in "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons; do
        [[ -d "$dir/$cand/cursors" ]] && { CURSOR_THEME="$cand"; break 2; }
    done
done
[[ -z "$CURSOR_THEME" ]] && CURSOR_THEME="default"

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme     "$GTK_THEME"
    gsettings set org.gnome.desktop.interface icon-theme    "$ICON_THEME"
    gsettings set org.gnome.desktop.interface cursor-theme  "$CURSOR_THEME"
    gsettings set org.gnome.desktop.interface cursor-size   "$CURSOR_SIZE"
    gsettings set org.gnome.desktop.interface color-scheme  'prefer-dark'
    gsettings set org.gnome.desktop.interface font-name     "$UI_FONT"
fi

# Keep the GTK3/GTK4 ini files in agreement with what was actually resolved.
# GTK3 on Wayland reads these directly; without them, floating GTK dialogs
# (pavucontrol, blueman, nm-connection-editor) fall back to the light default.
for ver in 3.0 4.0; do
    ini="$HOME/.config/gtk-$ver/settings.ini"
    [[ -f "$ini" ]] || continue
    sed -i \
        -e "s|^gtk-theme-name=.*|gtk-theme-name=$GTK_THEME|" \
        -e "s|^gtk-icon-theme-name=.*|gtk-icon-theme-name=$ICON_THEME|" \
        -e "s|^gtk-cursor-theme-name=.*|gtk-cursor-theme-name=$CURSOR_THEME|" \
        "$ini"
done

# Apply to the live sway seat and to the environment new clients inherit.
if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    swaymsg "seat seat0 xcursor_theme \"$CURSOR_THEME\" $CURSOR_SIZE" >/dev/null 2>&1 || true
fi
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    XCURSOR_THEME="$CURSOR_THEME" XCURSOR_SIZE="$CURSOR_SIZE" \
        dbus-update-activation-environment --systemd XCURSOR_THEME XCURSOR_SIZE >/dev/null 2>&1 || true
fi

exit 0
