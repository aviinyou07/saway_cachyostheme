#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO // WALLPAPER DAEMON  (the single owner of swaybg)
# ==============================================================================
# Previously this script and wallpaper-switch.sh were BOTH setting the wallpaper
# by independent means -- this one via `killall swaybg` + respawn on a timer, the
# other via `swaymsg output * bg`. Any manual pick was destroyed on the next tick.
#
# Now: this daemon is the only thing that ever talks to swaybg. wallpaper-switch.sh
# is a pure client -- it writes the desired state and sends SIGUSR1. A flock makes
# `exec_always` idempotent across `swaymsg reload`.
#
# State lives under XDG_STATE_HOME (never in ~/.config), so machine-local runtime
# data can't be committed back into the dotfiles repo.
# ==============================================================================
set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cyber-studio"
STATE_FILE="$STATE_DIR/wallpaper.state"
LOCK_FILE="$STATE_DIR/wallpaper.lock"
PID_FILE="$STATE_DIR/wallpaper.pid"
WALL_DIR="$HOME/.config/sway/wallpapers"
FALLBACK_COLOR="#090C14"

mkdir -p "$STATE_DIR"

# ------------------------------------------------------------------------------
# One-time migration from the old split state files in ~/.config/sway
# ------------------------------------------------------------------------------
_migrate_legacy() {
    [[ -f "$STATE_FILE" ]] && return 0
    local old_state="$HOME/.config/sway/.wallpaper_rotator_state"
    local old_interval="$HOME/.config/sway/.wallpaper_rotator_interval"
    local rotate="off" interval=1800
    [[ -f "$old_state" ]] && [[ "$(cat "$old_state" 2>/dev/null)" != "disabled" ]] && rotate="on"
    [[ -f "$old_interval" ]] && interval=$(cat "$old_interval" 2>/dev/null)
    [[ "$interval" =~ ^[0-9]+$ ]] || interval=1800

    # Adopt whatever the currently-running swaybg is showing, so migrating does
    # not visibly change the user's wallpaper out from under them.
    local current="" args
    args=$(pgrep -x swaybg >/dev/null 2>&1 && tr '\0' '\n' < /proc/"$(pgrep -x swaybg | head -1)"/cmdline 2>/dev/null)
    if [[ -n "$args" ]]; then
        current=$(printf '%s\n' "$args" | grep -A1 -x -- '-i' | tail -1)
        [[ -f "$current" ]] || current=""
    fi

    printf 'current=%s\nrotate=%s\ninterval=%s\n' "$current" "$rotate" "$interval" > "$STATE_FILE"
    rm -f "$old_state" "$old_interval"
}

# ------------------------------------------------------------------------------
# State accessors -- deliberately dumb key=value, no eval of file contents
# ------------------------------------------------------------------------------
state_get() {
    local key="$1" default="${2-}" val
    val=$(grep -m1 "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2-)
    printf '%s' "${val:-$default}"
}

list_wallpapers() {
    find "$WALL_DIR" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
        -print0 2>/dev/null | sort -z
}

# ------------------------------------------------------------------------------
# Apply a wallpaper by handing off to a fresh swaybg, then retiring the old one.
# Starting the replacement BEFORE killing the incumbent avoids the black flash
# the previous `killall`-first ordering produced on every rotation.
# ------------------------------------------------------------------------------
CURRENT_SWAYBG_PID=""
apply_wallpaper() {
    local img="$1" old_pid="$CURRENT_SWAYBG_PID"
    [[ -f "$img" ]] || return 1

    swaybg -o '*' -i "$img" -m fill -c "$FALLBACK_COLOR" >/dev/null 2>&1 9>&- &
    CURRENT_SWAYBG_PID=$!

    # Give the new surface a moment to be committed before retiring the old one.
    sleep 0.35
    if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null || true
    fi
    # Retire other wallpaper-setting swaybg instances, skipping (a) our own and
    # (b) sway's own argument-less swaybg. Sway keeps a bare `swaybg` child alive
    # and respawns it if killed -- fighting it produces an endless churn, and it
    # paints nothing anyway.
    local stray args
    for stray in $(pgrep -x swaybg 2>/dev/null); do
        [[ "$stray" == "$CURRENT_SWAYBG_PID" ]] && continue
        args=$(tr '\0' ' ' < "/proc/$stray/cmdline" 2>/dev/null)
        [[ "$args" == *" -i "* ]] || continue   # no image => not ours to manage
        kill "$stray" 2>/dev/null || true
    done
    return 0
}

# ------------------------------------------------------------------------------
# Signal handling: SIGUSR1 = "state changed, re-read and apply now"
# ------------------------------------------------------------------------------
RELOAD=0
trap 'RELOAD=1' USR1
trap 'exit 0' TERM INT

interruptible_sleep() {
    local secs="$1"
    sleep "$secs" 9>&- &
    local sp=$!
    wait "$sp" 2>/dev/null || true   # `wait` returns early when a trap fires
    kill "$sp" 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    _migrate_legacy

    local -a walls=()
    local current rotate interval idx=0

    while true; do
        RELOAD=0
        mapfile -d '' -t walls < <(list_wallpapers)

        current=$(state_get current)
        rotate=$(state_get rotate off)
        interval=$(state_get interval 1800)
        [[ "$interval" =~ ^[0-9]+$ ]] && (( interval >= 5 )) || interval=1800

        if (( ${#walls[@]} == 0 )); then
            interruptible_sleep 60
            continue
        fi

        # Resolve the index of the current wallpaper, if it is still on disk.
        idx=-1
        if [[ -n "$current" && -f "$current" ]]; then
            local i
            for i in "${!walls[@]}"; do
                [[ "${walls[$i]}" == "$current" ]] && { idx=$i; break; }
            done
        fi

        if [[ "$rotate" == "on" ]]; then
            # Advance one step per tick; wrap. A fresh state starts at the first.
            idx=$(( (idx + 1) % ${#walls[@]} ))
            current="${walls[$idx]}"
            set_state current "$current"
        elif (( idx < 0 )); then
            # Rotation off and nothing valid selected -> settle on the first.
            current="${walls[0]}"
            set_state current "$current"
        fi

        apply_wallpaper "$current"

        if [[ "$rotate" == "on" ]]; then
            interruptible_sleep "$interval"
        else
            # Static: nothing to do until a client signals a change.
            interruptible_sleep 86400
        fi
    done
}

set_state() {
    local key="$1" val="$2" tmp
    tmp=$(mktemp "$STATE_DIR/.state.XXXXXX")
    if [[ -f "$STATE_FILE" ]]; then
        grep -v "^${key}=" "$STATE_FILE" > "$tmp" 2>/dev/null || true
    fi
    printf '%s=%s\n' "$key" "$val" >> "$tmp"
    mv -f "$tmp" "$STATE_FILE"
}

# flock makes this safe under `exec_always`: a second instance simply exits.
# Every child is spawned with 9>&- so an orphan can never keep the lock alive.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    # Already running -- nudge the incumbent so a reload still re-applies state.
    # Signal via the PID file, never `pkill -f`, which would also match us.
    incumbent=$(cat "$PID_FILE" 2>/dev/null)
    [[ "$incumbent" =~ ^[0-9]+$ ]] && kill -USR1 "$incumbent" 2>/dev/null || true
    exit 0
fi

echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

main
