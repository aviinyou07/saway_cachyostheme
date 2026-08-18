#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // BLUETOOTH BAR ACTION
# ==============================================================================
# left click  -> off: turn it on.  on: open the manager.
# right click -> turn it off.
#
# Why this is not just `bluetoothctl power on`
# ------------------------------------------------------------------------------
# The adapter here is soft-blocked by rfkill, not merely powered down, and in
# that state BlueZ refuses outright:
#     Failed to set power on: org.bluez.Error.Failed
# The block has to be lifted first. `rfkill unblock` needs no root on this
# system, and lifting it powers the adapter on by itself -- the explicit
# `power on` afterwards is only for adapters that do not.
#
# The old binding went straight to blueman-manager, which meant clicking a
# disabled Bluetooth icon opened a window that could not enable it either.
# ==============================================================================
set -uo pipefail

note() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 "$@" || true; }

blocked() { rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes'; }
powered() { bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; }

case "${1:-open}" in
    open)
        if blocked || ! powered; then
            rfkill unblock bluetooth 2>/dev/null
            bluetoothctl power on >/dev/null 2>&1
            sleep 0.5
            if powered; then
                note "󰂯 Bluetooth" "Turned on"
            else
                note "󰂲 Bluetooth" "Could not turn on — check rfkill/hardware switch"
            fi
        else
            command -v blueman-manager >/dev/null 2>&1 && exec blueman-manager
            note "󰂯 Bluetooth" "blueman-manager is not installed"
        fi
        ;;
    off)
        bluetoothctl power off >/dev/null 2>&1
        rfkill block bluetooth 2>/dev/null
        note "󰂲 Bluetooth" "Turned off"
        ;;
    *)
        echo "usage: ${0##*/} [open|off]" >&2; exit 2 ;;
esac
