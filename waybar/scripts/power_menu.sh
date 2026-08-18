#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // SYSTEM POWER MENU
# ==============================================================================
# Invoked from two places:
#   * the Waybar power glyph  (custom/power -> on-click)
#   * the physical power key  (sway: bindsym XF86PowerOff)
#
# ------------------------------------------------------------------------------
# Why this script was rewritten
# ------------------------------------------------------------------------------
# The menu opened but no entry did anything. Three separate causes:
#
#  1. wofi activates entries on a DOUBLE click by default (`single_click` is
#     false in wofi(5)). Single-clicking an entry highlighted it, wofi exited
#     printing nothing, and the `case` fell through to its silent no-op branch.
#     Fixed by `single_click=true` in the dmenu profile below.
#
#  2. The menu reused the drun launcher config, which enables image and pango
#     markup escape parsing -- parsers that have no business touching plain
#     menu text. It now uses a dedicated dmenu profile.
#
#  3. "Lock Display" could never have worked regardless: ~/.config/swaylock/config
#     contained options that only exist in swaylock-EFFECTS, and upstream
#     swaylock aborts on an unrecognised option rather than warning. That
#     config has been corrected separately.
#
# Matching is done on a distinctive word rather than the full decorated label,
# so re-theming an icon or changing spacing cannot silently break dispatch again.
# ==============================================================================
set -uo pipefail

WOFI_CONF="$HOME/.config/wofi/dmenu.conf"
WOFI_STYLE="$HOME/.config/wofi/style.css"
LOCK=("$HOME/.config/sway/scripts/lock.sh")

# Pressing the power key (or the Waybar glyph) while the menu is already up
# closes it, rather than stacking a second identical menu on top.
if pgrep -x wofi >/dev/null 2>&1; then
    pkill -x wofi
    exit 0
fi

# Detach an action from this script so it outlives the process Waybar spawned.
run() { setsid --fork "$@" >/dev/null 2>&1; }

CHOSEN=$(printf '%s\n' \
    "󰌾  Lock Display" \
    "󰍃  End Session (Logout)" \
    "󰒲  Suspend to RAM" \
    "󰜉  System Reboot" \
    "󰐥  Power Off" \
  | wofi --dmenu \
         --conf "$WOFI_CONF" \
         --style "$WOFI_STYLE" \
         --prompt "Power" \
         --width 400 \
         --height 430 \
         --lines 5 \
         --cache-file /dev/null)

# wofi exits non-zero / prints nothing when dismissed with Escape.
[ -n "${CHOSEN:-}" ] || exit 0

case "$CHOSEN" in
    *Lock*)
        run "${LOCK[@]}"
        ;;
    *Logout*)
        swaymsg exit
        ;;
    *Suspend*)
        # Do NOT lock here. swayidle owns the `before-sleep` hook and locks on
        # the way down; locking from this script as well races it and can leave
        # two swaylock instances fighting for the session lock.
        run systemctl suspend
        ;;
    *Reboot*)
        run systemctl reboot
        ;;
    *"Power Off"*)
        run systemctl poweroff
        ;;
esac
