#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // CLIPBOARD HISTORY PICKER  (wofi -- FALLBACK)
# ==============================================================================
# Superseded by clipboard-gui.py, which every binding now points at. This is
# kept, not dead weight: the GTK app depends on python-gobject/gtk4/libadwaita,
# and on a rolling release those can break on an update. When they do, pointing
# $clipmenu back at this file restores a working picker with no dependencies
# beyond wofi.
#
# It cannot do what the GTK version does -- wofi is a dmenu, so there is no
# header bar and no per-row delete button; its actions are list rows instead.
#
# Originally replaced the inline `cliphist list | wofi | cliphist decode |
# wl-copy` pipeline that was duplicated across bindings.conf and the Waybar
# module.
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

# ------------------------------------------------------------------------------
# Thumbnails
# ------------------------------------------------------------------------------
# Image entries all render as "[[ binary data 2 MiB png 1920x1080 ]]" -- and this
# store is mostly screenshots, so the list was a wall of identical rows with no
# way to tell one from another. Decoding each into a small thumbnail turns that
# back into something you can actually pick from.
#
# Bounded on purpose: decode+resize costs ~47ms per image, so converting a full
# 750-entry history would add half a minute to opening the menu. Only the newest
# THUMB_LIMIT images are rendered -- the ones actually being reached for -- and
# results are cached by entry id, so any entry is converted at most once.
THUMB_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cyber-noir-clipthumbs"
THUMB_LIMIT=25

build_menu() {
    if ! command -v magick >/dev/null 2>&1; then printf '%s\n' "$ENTRIES"; return; fi
    mkdir -p "$THUMB_DIR" 2>/dev/null || { printf '%s\n' "$ENTRIES"; return; }

    # One transparent 44x44 png, generated once, reused for every text row.
    local SPACER="$THUMB_DIR/.spacer.png"
    if [[ ! -s "$SPACER" ]]; then
        magick -size 44x44 xc:none "$SPACER" 2>/dev/null || SPACER=""
    fi

    local line id thumb made=0
    while IFS= read -r line; do
        if (( made < THUMB_LIMIT )) && [[ "$line" == *"binary data"* ]] \
           && [[ "$line" =~ (png|jpe?g|gif|webp|bmp) ]]; then
            id="${line%%$'\t'*}"
            if [[ "$id" =~ ^[0-9]+$ ]]; then
                thumb="$THUMB_DIR/$id.png"
                if [[ ! -s "$thumb" ]]; then
                    # -thumbnail strips metadata as well as resizing, so nothing
                    # from the original travels into the cache.
                    printf '%s' "$line" | cliphist decode 2>/dev/null \
                      | magick - -thumbnail 44x44 "$thumb" 2>/dev/null || thumb=""
                fi
                if [[ -n "$thumb" && -s "$thumb" ]]; then
                    made=$((made + 1))
                    printf 'img:%s:text:%s\n' "$thumb" "$line"
                    continue
                fi
            fi
        fi
        # Text rows get a transparent spacer of the same size. Without it the
        # id column jumps left on every non-image row, because only image rows
        # are indented by their thumbnail -- the list stops reading as columns.
        if [[ -n "$SPACER" ]]; then
            printf 'img:%s:text:%s\n' "$SPACER" "$line"
        else
            printf '%s\n' "$line"
        fi
    done <<< "$ENTRIES"
}

# Drop thumbnails whose entry is gone, so the cache cannot grow without bound as
# the history rolls over.
prune_thumbs() {
    [[ -d "$THUMB_DIR" ]] || return 0
    local ids f base
    ids="$(printf '%s' "$ENTRIES" | cut -f1)"
    for f in "$THUMB_DIR"/*.png; do
        [[ -e "$f" ]] || continue
        base="${f##*/}"
        [[ "$base" == ".spacer.png" ]] && continue
        base="${base%.png}"
        grep -qx -- "$base" <<< "$ids" || rm -f -- "$f"
    done
}
prune_thumbs


if [[ -z "$ENTRIES" ]]; then
    printf '%s\n%s\n' "$ACT_SHOT" "󰋼   Clipboard history is empty" \
      | menu_small --prompt "Clipboard" --width 460 --height 250 --lines 2 | grep -q "Screenshot" \
      && exec "$HOME/.config/sway/scripts/screenshot.sh" copy
    exit 0
fi

# Entries FIRST, actions last. wofi pre-selects row one, so with the actions on
# top the reflex of "open picker, hit Enter" fired a screenshot instead of
# pasting the most recent item -- the single most common thing this menu is for.
CHOSEN="$(printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$(build_menu)" "$SEP" \
                 "$ACT_SHOT" "$ACT_DEL" "$ACT_RESTORE" "$ACT_CLEAR" \
          | menu --prompt "Clipboard   ·   type  del  shot  clear  restore")"
[[ -n "$CHOSEN" ]] || exit 0

# wofi echoes the row back verbatim, img: prefix and all, so it comes off before
# cliphist sees it. Shortest-match: a copied string containing a literal ":text:"
# must not be truncated.
CHOSEN="${CHOSEN#img:*:text:}"

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
