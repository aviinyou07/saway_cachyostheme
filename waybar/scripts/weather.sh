#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO WAYBAR // WEATHER
# ==============================================================================
# Two changes from the original:
#
#  1. Nerd Font glyphs instead of wttr.in's colour emoji. The emoji rendered in
#     full colour via Noto Color Emoji and was the only non-monochrome element in
#     the bar, which made it look pasted in.
#
#  2. A single request with an explicit timeout. The original made TWO uncapped
#     curl calls per tick -- if wttr.in hung, the module hung with it.
# ==============================================================================
set -uo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/cyber-studio-weather"
TIMEOUT=8

emit_none() { printf '{"text": "", "class": "offline"}\n'; exit 0; }

command -v curl >/dev/null 2>&1 || emit_none

# %C condition, %t temperature, %l location -- one request, pipe separated.
# NOTE: wttr.in emits a literal \t rather than a tab, so a pipe is the only
# separator that actually round-trips.
RAW=$(curl -sf --max-time "$TIMEOUT" \
        'https://wttr.in/?format=%C|%t|%l' 2>/dev/null) || RAW=""

if [[ -z "$RAW" || "$RAW" == *"Unknown location"* || "$RAW" == *"Sorry"* ]]; then
    # Serve the last good reading rather than blinking out on one failed poll.
    [[ -f "$CACHE" ]] && { cat "$CACHE"; exit 0; }
    emit_none
fi

IFS='|' read -r COND TEMP LOC <<< "$RAW"
COND=$(printf '%s' "$COND" | tr -d '\n')
TEMP=$(printf '%s' "$TEMP" | tr -d '\n +')
LOC=$(printf  '%s' "$LOC"  | tr -d '\n')
[[ -z "$TEMP" ]] && emit_none

# Map the textual condition onto Nerd Font weather glyphs.
shopt -s nocasematch
# Order matters: "Dust storm" must match *dust* before the generic *storm*.
case "$COND" in
    *dust*|*sand*)                   ICON="󰖝" ;;
    *thunder*|*lightning*)           ICON="󰙾" ;;
    *snow*|*sleet*|*ice*|*blizzard*) ICON="󰼶" ;;
    *rain*|*drizzle*|*shower*)       ICON="󰖗" ;;
    *storm*|*wind*|*gale*)           ICON="󰖝" ;;
    *fog*|*mist*|*haze*|*smoke*)     ICON="󰖑" ;;
    *overcast*)                      ICON="󰅟" ;;
    *cloud*)                         ICON="󰖕" ;;
    *clear*|*sunny*)                 ICON="󰖙" ;;
    *)                               ICON="󰔏" ;;
esac
shopt -u nocasematch

jq -cn --arg t "$ICON $TEMP" \
       --arg c "${COND:-Unknown}" \
       --arg l "${LOC:-Unknown location}" \
       --arg m "$TEMP" \
       '{text: $t, tooltip: ($c + "  " + $m + "\n" + $l), class: "normal"}' \
  | tee "$CACHE"
