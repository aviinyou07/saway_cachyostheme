#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO // WALLPAPER SWITCHER  (client -- never touches swaybg directly)
# ==============================================================================
# Writes the desired wallpaper into shared state and signals the daemon
# (wallpaper_rotator.sh), which is the single owner of swaybg. This is what
# stops a manual pick from being clobbered by the next rotation tick.
#
# Usage:  wallpaper-switch.sh [menu|-n|--next|-p|--prev|-r|--random]
# ==============================================================================
set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cyber-studio"
STATE_FILE="$STATE_DIR/wallpaper.state"
WALL_DIR="$HOME/.config/sway/wallpapers"
ROTATOR="$HOME/.config/sway/scripts/wallpaper_rotator.sh"
PID_FILE="$STATE_DIR/wallpaper.pid"
SDDM_DIR="/usr/share/sddm/themes/cyber-noir"
# dmenu profile, not the drun launcher one: the launcher config declares
# `show=drun` and enables image/markup escape parsing, which has no place
# in a plain-text picker. It also leaves wofi on its double-click default.
WOFI_CONF="$HOME/.config/wofi/dmenu.conf"
WOFI_STYLE="$HOME/.config/wofi/style.css"

mkdir -p "$STATE_DIR" "$WALL_DIR"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send "$@" || true; }

# Every wofi surface in this theme goes through the same config + stylesheet.
# A bare `wofi --dmenu` renders in default GTK grey and looks like a different OS.
wofi_menu() { wofi --dmenu --conf "$WOFI_CONF" --style "$WOFI_STYLE" "$@"; }

state_get() {
    local key="$1" default="${2-}" val
    val=$(grep -m1 "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2-)
    printf '%s' "${val:-$default}"
}

set_state() {
    local key="$1" val="$2" tmp
    tmp=$(mktemp "$STATE_DIR/.state.XXXXXX")
    [[ -f "$STATE_FILE" ]] && { grep -v "^${key}=" "$STATE_FILE" > "$tmp" 2>/dev/null || true; }
    printf '%s=%s\n' "$key" "$val" >> "$tmp"
    mv -f "$tmp" "$STATE_FILE"
}

# Wake the daemon so the change is applied immediately; start it if it is not up.
# Signal via the PID file. `pkill -f wallpaper_rotator` would also match THIS
# script's own command line and send the signal to ourselves.
signal_daemon() {
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
        kill -USR1 "$pid" 2>/dev/null || true
    else
        setsid "$ROTATOR" >/dev/null 2>&1 &
    fi
}

mapfile -d '' -t WALLPAPERS < <(
    find "$WALL_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print0 2>/dev/null | sort -z
)

if (( ${#WALLPAPERS[@]} == 0 )); then
    notify -u critical "Wallpaper" "No images found in ${WALL_DIR}"
    exit 1
fi

# Resolve the current index from shared state -- NOT by grepping a commented-out
# line in output.conf, which always failed and pinned every "next" to index 1.
CURRENT=$(state_get current)
CUR_IDX=-1
for i in "${!WALLPAPERS[@]}"; do
    [[ "${WALLPAPERS[$i]}" == "$CURRENT" ]] && { CUR_IDX=$i; break; }
done

MODE="${1:-menu}"
TARGET=""

case "$MODE" in
    -n|--next)   TARGET="${WALLPAPERS[$(( (CUR_IDX + 1) % ${#WALLPAPERS[@]} ))]}" ;;
    -p|--prev)   TARGET="${WALLPAPERS[$(( (CUR_IDX - 1 + ${#WALLPAPERS[@]}) % ${#WALLPAPERS[@]} ))]}" ;;
    -r|--random) TARGET="${WALLPAPERS[$(( RANDOM % ${#WALLPAPERS[@]} ))]}" ;;
    menu|*)
        ROTATE=$(state_get rotate off)
        INTERVAL=$(state_get interval 1800)

        {
            if [[ "$ROTATE" == "on" ]]; then
                printf '%s\n' "[ Disable Auto-Rotate ]"
            else
                printf '%s\n' "[ Enable Auto-Rotate ]"
            fi
            printf '%s\n' "[ Set Rotate Interval  (now: ${INTERVAL}s) ]"
            for w in "${WALLPAPERS[@]}"; do
                name=$(basename "$w"); name="${name%.*}"
                [[ "$w" == "$CURRENT" ]] && printf '❯ %s (Active)\n' "$name" || printf '  %s\n' "$name"
            done
        } > "$STATE_DIR/.menu"

        SELECTED=$(wofi_menu --prompt "󰸉 Wallpaper" --width 460 --lines 10 \
                       --cache-file /dev/null < "$STATE_DIR/.menu" 2>/dev/null \
                   | sed 's/^[❯[:space:]]*//; s/ (Active)$//')
        rm -f "$STATE_DIR/.menu"
        [[ -z "$SELECTED" ]] && exit 0

        case "$SELECTED" in
            "[ Enable Auto-Rotate ]")
                set_state rotate on; signal_daemon
                notify "󰸉 Wallpaper" "Auto-rotation enabled (every ${INTERVAL}s)"; exit 0 ;;
            "[ Disable Auto-Rotate ]")
                set_state rotate off; signal_daemon
                notify "󰸉 Wallpaper" "Auto-rotation disabled"; exit 0 ;;
            "[ Set Rotate Interval "*)
                NEW=$(printf '' | wofi_menu --prompt "Interval in seconds" --lines 1 \
                          --cache-file /dev/null 2>/dev/null)
                if [[ "$NEW" =~ ^[0-9]+$ ]] && (( NEW >= 5 )); then
                    set_state interval "$NEW"; signal_daemon
                    notify "󰸉 Wallpaper" "Rotation interval set to ${NEW}s"
                else
                    notify -u critical "󰸉 Wallpaper" "Interval must be a number >= 5"
                fi
                exit 0 ;;
        esac

        # Match the chosen basename back to a real file.
        for w in "${WALLPAPERS[@]}"; do
            base=$(basename "$w"); [[ "${base%.*}" == "$SELECTED" ]] && { TARGET="$w"; break; }
        done
        ;;
esac

if [[ -z "$TARGET" || ! -f "$TARGET" ]]; then
    notify -u critical "󰸉 Wallpaper" "Could not resolve the selected wallpaper"
    exit 1
fi

set_state current "$TARGET"
signal_daemon

# ------------------------------------------------------------------------------
# Optional: mirror the choice to the SDDM greeter background.
# ------------------------------------------------------------------------------
# We copy only when the target is already writable by this user; otherwise we
# record the exact command to run and move on. A desktop convenience script must
# never escalate privileges silently or cache a credential to do so.
if [[ -w "${SDDM_DIR}/background.png" ]]; then
    cp -f "$TARGET" "${SDDM_DIR}/background.png" 2>/dev/null || true
elif [[ -d "$SDDM_DIR" ]]; then
    printf 'sudo cp -f %q %q\n' "$TARGET" "${SDDM_DIR}/background.png" \
        > "$STATE_DIR/sync-sddm-background.txt"
fi

NAME=$(basename "$TARGET"); NAME="${NAME%.*}"
notify -t 2500 "󰸉 Wallpaper" "Switched to <b>${NAME}</b>"
exit 0
