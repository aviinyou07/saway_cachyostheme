#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO // IDLE & LOCK DAEMON SUPERVISOR
# ==============================================================================
# swayidle's invocation is nested quotes three deep (sway -> sh -c -> swayidle
# -> swaymsg "output * dpms off"). Sway's own config lexer mangles that, so the
# daemon silently never came up. Keeping the command in a script means only bash
# ever parses it.
#
# Restarting is handled here rather than as a separate `exec_always killall`,
# because sway spawns each exec asynchronously -- a separate kill directive
# routinely lands after the new process and kills it.
# ==============================================================================
set -uo pipefail

LOCK_CMD="$HOME/.config/sway/scripts/lock.sh"

# Retire any previous instance, then wait for it to actually be gone.
pkill -x swayidle 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x swayidle >/dev/null 2>&1 || break
    sleep 0.1
done

exec swayidle -w \
    timeout 300  "$LOCK_CMD" \
    timeout 360  'swaymsg "output * dpms off"' \
      resume     'swaymsg "output * dpms on"' \
    before-sleep "$LOCK_CMD" \
    lock         "$LOCK_CMD" \
    unlock       'swaymsg "output * dpms on"'
