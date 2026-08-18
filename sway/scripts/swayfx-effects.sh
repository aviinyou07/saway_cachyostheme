#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO // SWAYFX VISUAL EFFECTS (conditional)
# ==============================================================================
# Rounded corners, blur and shadows are SwayFX extensions. On upstream sway they
# are hard errors, so they cannot simply be listed in appearance.conf -- which is
# why they sat commented out while the README advertised them.
#
# This probes the running compositor and applies them only if they are supported,
# so one config works on both sway and swayfx.
# ==============================================================================
set -uo pipefail
command -v swaymsg >/dev/null 2>&1 || exit 0

# `swaymsg` returns success:false on an unknown command; use that as the probe.
supports() {
    swaymsg -t command "$1" 2>/dev/null | grep -q '"success": *true'
}

if supports "corner_radius 12"; then
    swaymsg "corner_radius 12"          >/dev/null 2>&1
    swaymsg "smart_corner_radius on"    >/dev/null 2>&1
    swaymsg "shadows enable"            >/dev/null 2>&1
    swaymsg "shadow_blur_radius 14"     >/dev/null 2>&1
    swaymsg "shadow_color #060911D9"    >/dev/null 2>&1
    swaymsg "blur enable"               >/dev/null 2>&1
    swaymsg "blur_passes 2"             >/dev/null 2>&1
    swaymsg "blur_radius 5"             >/dev/null 2>&1
    swaymsg "blur_xray disable"         >/dev/null 2>&1
    swaymsg "layer_effects 'waybar' blur enable; shadows enable; corner_radius 10" >/dev/null 2>&1
fi
exit 0
