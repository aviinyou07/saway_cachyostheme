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
ACT_DEL="󰆴   Delete a single entry"
ACT_RESTORE="󰕌   Restore last backup"
SEP="─────────────────────────────────────────"

note() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 "$@" || true; }

# Toggle: a second press closes the picker instead of stacking another.
if pgrep -x wofi >/dev/null 2>&1; then pkill -x wofi; exit 0; fi

# ------------------------------------------------------------------------------
# Backups
# ------------------------------------------------------------------------------
# `cliphist wipe` destroys the store outright and cliphist has no undo. A 260MB
# history was lost here during development without the cause ever being pinned
# down, which is the whole argument for this: the safety of a destructive action
# should not rest on nobody ever triggering it by accident.
#
# The db is a single file, so a copy is a complete backup. Backups live beside
# the store, are timestamped, and the newest BACKUP_KEEP are retained.
DB="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/db"
BACKUP_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/backups"
BACKUP_KEEP=5

backup_db() {
    [[ -s "$DB" ]] || return 0
    mkdir -p "$BACKUP_DIR" || return 1
    local dest="$BACKUP_DIR/db-$(date +%Y%m%d-%H%M%S)"
    cp -f "$DB" "$dest" 2>/dev/null || return 1
    # Prune oldest beyond BACKUP_KEEP. `find -printf` + sort is used rather than
    # ls so filenames are never parsed.
    local old
    while read -r old; do rm -f -- "$old"; done < <(
        find "$BACKUP_DIR" -maxdepth 1 -type f -name 'db-*' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | tail -n +$((BACKUP_KEEP + 1)) | cut -d' ' -f2-)
    printf '%s' "$dest"
}

latest_backup() {
    find "$BACKUP_DIR" -maxdepth 1 -type f -name 'db-*' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-
}

restore_backup() {
    local b; b="$(latest_backup)"
    [[ -n "$b" && -s "$b" ]] || { note "󰕌 Clipboard" "No backup to restore"; return 0; }
    local when; when="$(basename "$b")"; when="${when#db-}"
    local c
    c="$(printf '%s\n%s\n' "󰜺   Cancel" "󰕌   Restore backup from ${when}" \
         | menu_small --prompt "Restore clipboard?" --width 460 --height 250 --lines 2)"
    [[ "$c" == *"Restore"* ]] || return 0
    # Back up the CURRENT store first, so restoring is itself reversible.
    backup_db >/dev/null
    cp -f "$b" "$DB" 2>/dev/null \
      && note "󰕌 Clipboard" "Restored $(cliphist list 2>/dev/null | wc -l) entries" \
      || note "󰕌 Clipboard" "Restore failed"
}

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
    [[ "$c" == *"Delete all"* ]] || return 0
    local b; b="$(backup_db)"
    if cliphist wipe; then
        if [[ -n "$b" ]]; then
            note "󰩹 Clipboard" "Cleared ${n} entries — restorable from the picker"
        else
            note "󰩹 Clipboard" "Cleared ${n} entries (backup failed)"
        fi
    fi
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
CHOSEN="$(printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$ENTRIES" "$SEP" \
                 "$ACT_SHOT" "$ACT_DEL" "$ACT_RESTORE" "$ACT_CLEAR" \
          | menu --prompt "Clipboard   ·   type  del  shot  clear  restore")"
[[ -n "$CHOSEN" ]] || exit 0

case "$CHOSEN" in
    "$SEP") exit 0 ;;
    "$ACT_SHOT") exec "$HOME/.config/sway/scripts/screenshot.sh" copy ;;
    "$ACT_CLEAR") confirm_wipe; exit 0 ;;
    "$ACT_RESTORE") restore_backup; exit 0 ;;
    "$ACT_DEL")
        # Removing one entry matters more than it sounds: everything copied ends
        # up here, passwords included, and until now the only way to get a single
        # secret out of the store was to destroy all 750 entries with it.
        VICTIM="$(printf '%s\n' "$ENTRIES" | menu --prompt "Delete which entry?")"
        [[ -n "$VICTIM" ]] || exit 0
        printf '%s' "$VICTIM" | cliphist delete \
          && note "󰆴 Clipboard" "Entry deleted" \
          || note "󰆴 Clipboard" "Delete failed"
        exit 0 ;;
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
