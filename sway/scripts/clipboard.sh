#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // CLIPBOARD HISTORY PICKER
# ==============================================================================
# Replaces the inline `cliphist list | wofi | cliphist decode | wl-copy` pipeline
# that used to be duplicated across bindings.conf and the Waybar module.
#
# Three things that pipeline could not do:
#
#  1. PASTE. It only refilled the clipboard, so picking an entry still left you
#     to press the paste key yourself. Selecting an item now types the paste
#     shortcut into whatever had focus before the menu opened -- and it picks the
#     right shortcut, because terminals bind Ctrl+Shift+V while everything else
#     uses Ctrl+V. Sending Ctrl+V to a terminal does nothing at best and triggers
#     an unrelated binding at worst.
#
#  2. CLEAR. There was no way to empty the history from the UI. `cliphist wipe`
#     is unrecoverable and the store here reached 260MB, so it asks first.
#
#  3. SCREENSHOT. wofi takes an EXCLUSIVE keyboard grab on its layer surface, so
#     while the picker is open sway never sees Print and the screenshot binding
#     appears dead. That is wofi's behaviour and cannot be configured away, so
#     the action is offered inside the menu instead of fighting for the key.
#
# Focus is sampled BEFORE wofi opens: once the picker is up, wofi itself is the
# focused surface, so asking afterwards would always answer "wofi".
# ==============================================================================
set -uo pipefail

WOFI_CONF="$HOME/.config/wofi/clipboard.conf"
WOFI_STYLE="$HOME/.config/wofi/clipboard.css"

ACT_CLEAR="󰩹   Clear clipboard history"
ACT_SHOT="󰄀   Screenshot a region to clipboard"
SEP="─────────────────────────────────────────"

note() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 "$@" || true; }

# Toggle: a second press closes the picker instead of stacking another.
if pgrep -x wofi >/dev/null 2>&1; then pkill -x wofi; exit 0; fi

confirm_wipe() {
    local n; n="$(cliphist list 2>/dev/null | wc -l)"
    if [[ "$n" -eq 0 ]]; then note "󰩹 Clipboard" "History is already empty"; return 0; fi
    # The destructive option is never the default: Escape and row one both keep
    # the history, so a stray Enter cannot wipe 750 entries.
    local c
    # Explicit geometry: clipboard.conf sizes the PICKER (920x600, 12 rows) and
    # those values carry into every wofi call made from here. Left alone, the
    # confirm box inherited a height that clipped its second row -- so the
    # destructive option was invisible and only "Keep history" could be seen.
    c="$(printf '%s\n%s\n' "󰜺   Keep history" "󰩹   Delete all ${n} entries" \
         | menu_small --prompt "Clear clipboard?" --width 460 --height 250 --lines 2)"
    [[ "$c" == *"Delete all"* ]] && { cliphist wipe && note "󰩹 Clipboard" "History cleared (${n} entries)"; }
    return 0
}

# ------------------------------------------------------------------------------
# Remember what to paste into, before wofi steals focus
# ------------------------------------------------------------------------------
TARGET_APP=""
if command -v jq >/dev/null 2>&1; then
    TARGET_APP=$(swaymsg -t get_tree 2>/dev/null | jq -r '
        recurse(.nodes[]?, .floating_nodes[]?)
        | select(.focused == true)
        | (.app_id // .window_properties.class // "") ' 2>/dev/null | head -1)
fi

# The wide picker profile: 920x600, 12 rows, roomy rows tuned for long text.
menu() {
    wofi --dmenu --conf "$WOFI_CONF" --style "$WOFI_STYLE" --cache-file /dev/null "$@"
}

# Small prompts (confirm, empty-history) use the POWER MENU profile instead.
# Reusing the picker profile for a two-row dialog clipped the second row: wofi
# derives its height from font metrics rather than from the stylesheet, and the
# picker's taller rows overflow whatever it allocates -- passing --lines or
# --height does not move it. dmenu.conf/style.css already sizes short menus
# correctly, which is exactly what the five-entry power menu relies on.
menu_small() {
    wofi --dmenu --conf "$HOME/.config/wofi/dmenu.conf" \
         --style "$HOME/.config/wofi/style.css" --cache-file /dev/null "$@"
}

# 80, not cliphist's default 100. At 13.5px monospace in a 920px window a
# 100-char preview runs off the right edge and the tail is simply lost.
# Waybar right-clicks straight into the clear flow; the picker itself never has
# to be opened to empty the history.
[[ "${1:-}" == "clear" ]] && { confirm_wipe; exit 0; }

ENTRIES="$(cliphist -preview-width 80 list 2>/dev/null)"

if [[ -z "$ENTRIES" ]]; then
    printf '%s\n%s\n' "$ACT_SHOT" "󰋼   Clipboard history is empty" \
      | menu_small --prompt "Clipboard" --width 460 --height 250 --lines 2 | grep -q "Screenshot" \
      && exec "$HOME/.config/sway/scripts/screenshot.sh" copy
    exit 0
fi

# Entries FIRST, actions last. wofi pre-selects row one, so with the actions on
# top the reflex of "open picker, hit Enter" fired a screenshot instead of
# pasting the most recent item -- the single most common thing this menu is for.
CHOSEN="$(printf '%s\n%s\n%s\n%s\n' "$ENTRIES" "$SEP" "$ACT_SHOT" "$ACT_CLEAR" \
          | menu --prompt "Clipboard   ·   type  clear  or  shot  for actions")"
[[ -n "$CHOSEN" ]] || exit 0

case "$CHOSEN" in
    "$SEP") exit 0 ;;
    "$ACT_SHOT") exec "$HOME/.config/sway/scripts/screenshot.sh" copy ;;
    "$ACT_CLEAR") confirm_wipe; exit 0 ;;
esac

# ------------------------------------------------------------------------------
# Copy, then paste into the window that had focus
# ------------------------------------------------------------------------------
printf '%s' "$CHOSEN" | cliphist decode | wl-copy || { note "Clipboard" "Copy failed"; exit 1; }

command -v wtype >/dev/null 2>&1 || exit 0

# Give sway a moment to hand focus back to TARGET_APP; typing into a surface
# that is still being torn down goes nowhere.
sleep 0.15

case "$TARGET_APP" in
    kitty|foot|Alacritty|alacritty|org.wezfurlong.wezterm|com.mitchellh.ghostty|ghostty|xterm|URxvt|st|org.kde.konsole|dev.warp.Warp)
        wtype -M ctrl -M shift -k v -m shift -m ctrl ;;
    "")
        # Focus could not be determined -- copying already succeeded, so stop
        # rather than firing a keystroke at an unknown window.
        ;;
    *)
        wtype -M ctrl -k v -m ctrl ;;
esac
