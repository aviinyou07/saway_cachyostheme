#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO // DISPLAY SETTINGS LAUNCHER
# ==============================================================================
# XF86Display was bound directly to `nwg-displays`, which is optional and was not
# in the installer's package list -- so on most machines the key did nothing at
# all, silently. Try the known GUIs in order and, failing all of them, say so
# instead of no-oping.
# ==============================================================================
set -uo pipefail

for app in nwg-displays wdisplays wlr-randr-gui; do
    if command -v "$app" >/dev/null 2>&1; then
        exec "$app"
    fi
done

if command -v notify-send >/dev/null 2>&1; then
    notify-send -u normal "󰍹 Display settings" \
        "No display configuration tool found.\nInstall <b>nwg-displays</b> or <b>wdisplays</b>."
fi
exit 0
