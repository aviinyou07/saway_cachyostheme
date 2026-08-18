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
SUSPEND_CMD="$HOME/.config/sway/scripts/idle-suspend.sh"

# Retire any previous instance, then wait for it to actually be gone.
pkill -x swayidle 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x swayidle >/dev/null 2>&1 || break
    sleep 0.1
done

# Tier 3 (900s) is new. Before it, the chain ended at `dpms off`: the screen
# went black and the machine then stayed fully awake indefinitely, which is
# indistinguishable from sleep until the battery is flat. idle-suspend.sh only
# acts when unplugged -- see the reasoning in that script.
exec swayidle -w \
    timeout 300  "$LOCK_CMD" \
    timeout 360  'swaymsg "output * dpms off"' \
      resume     'swaymsg "output * dpms on"' \
    timeout 900  "$SUSPEND_CMD" \
    before-sleep "$LOCK_CMD" \
    lock         "$LOCK_CMD" \
    unlock       'swaymsg "output * dpms on"'
