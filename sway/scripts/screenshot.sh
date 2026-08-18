#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // SCREENSHOT
# ==============================================================================
# Modes:  full    entire desktop -> file + clipboard
#         region  drag a box     -> file + clipboard
#         copy    drag a box     -> clipboard only
#
# Why this is a script now
# ------------------------------------------------------------------------------
# These were three inline `bindsym exec` one-liners, and two of them were wrong:
#
#   * $mod+Print ran slurp TWICE on the same line -- once to size the saved file
#     and again to size the clipboard copy. You drew the box, it saved, and then
#     the selector reopened and made you draw it a second time.
#   * Print ran grim twice, so the file and the clipboard were two separate
#     captures taken moments apart rather than one image going to both places.
#
# Both are the same underlying mistake: a capture is a value, so it has to be
# taken once and then fanned out, which inline `&&` chains cannot express without
# a variable. `tee` does the fan-out here; slurp's geometry is captured once into
# GEOM. Keeping it in a file also means only bash parses the nested quoting in
# slurp's colour flags, which is what made the originals so awkward to read.
# ==============================================================================
set -uo pipefail

ROOT="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
STAMP="$(date +%Y%m%d_%H%M%S)"

# Captures land in a per-month folder. A single flat directory had reached 716
# files and 290MB here, which is not a disk problem so much as an unusable one:
# nothing can be found in it and nothing can be pruned selectively.
#
# Existing screenshots are deliberately NOT moved. They are your files, and
# silently reorganising a folder someone may have linked or scripted against is
# not a tidy-up. `screenshot.sh tidy` does it on request; `screenshot.sh prune
# <days>` deletes captures older than N days, also only when asked.
DIR="${ROOT}/$(date +%Y-%m)"

# slurp styled to the Cyber Studio palette: accent border, dimmed backdrop.
SLURP_ARGS=(-c 38BDF8 -b 090C14A6 -s 38BDF81A -w 2)

note() { command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 "$@" || true; }

mkdir -p "$DIR" || { note "Screenshot" "Cannot write to $DIR"; exit 1; }

case "${1:-full}" in
    tidy)
        # One-off: sort loose captures into the month they were taken.
        moved=0
        while IFS= read -r f; do
            m=$(date -r "$f" +%Y-%m) || continue
            mkdir -p "${ROOT}/${m}" || continue
            mv -n -- "$f" "${ROOT}/${m}/" && moved=$((moved + 1))
        done < <(find "$ROOT" -maxdepth 1 -type f -name '*.png')
        echo "moved ${moved} screenshot(s) into month folders"
        exit 0
        ;;
    prune)
        days="${2:-}"
        if ! [[ "$days" =~ ^[0-9]+$ ]]; then
            echo "usage: ${0##*/} prune <days>   (deletes captures older than N days)" >&2
            exit 2
        fi
        n=$(find "$ROOT" -type f -name '*.png' -mtime "+${days}" | wc -l)
        find "$ROOT" -type f -name '*.png' -mtime "+${days}" -delete
        find "$ROOT" -mindepth 1 -type d -empty -delete
        echo "deleted ${n} screenshot(s) older than ${days} days"
        exit 0
        ;;
    full)
        FILE="$DIR/capture_${STAMP}.png"
        # One capture, tee'd: the file and the clipboard are the same pixels.
        grim - | tee "$FILE" | wl-copy || { note "Screenshot" "Capture failed"; exit 1; }
        note "󰄀 Screenshot" "Full desktop → clipboard + ${FILE##*/}"
        ;;
    region)
        # Select ONCE. Empty means the user pressed Escape -- not an error.
        GEOM="$(slurp "${SLURP_ARGS[@]}" 2>/dev/null)" || exit 0
        [[ -n "$GEOM" ]] || exit 0
        FILE="$DIR/region_${STAMP}.png"
        grim -g "$GEOM" - | tee "$FILE" | wl-copy || { note "Screenshot" "Capture failed"; exit 1; }
        note "󰄀 Screenshot" "Region → clipboard + ${FILE##*/}"
        ;;
    copy)
        GEOM="$(slurp "${SLURP_ARGS[@]}" 2>/dev/null)" || exit 0
        [[ -n "$GEOM" ]] || exit 0
        grim -g "$GEOM" - | wl-copy || { note "Screenshot" "Capture failed"; exit 1; }
        note "󰄀 Screenshot" "Region copied to clipboard"
        ;;
    *)
        echo "usage: ${0##*/} [full|region|copy|tidy|prune <days>]" >&2
        exit 2
        ;;
esac
