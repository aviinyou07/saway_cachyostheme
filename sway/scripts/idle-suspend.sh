#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // IDLE SUSPEND (battery only)
# ==============================================================================
# swayidle's last tier used to be `dpms off` at 360s, and nothing after it. The
# machine locked, the panel went dark, and it then sat fully awake until the
# battery ran out -- which looks exactly like sleep, so it never got noticed.
#
# Suspend is gated on being unplugged rather than fired unconditionally, because
# swayidle measures INPUT idleness, not work. A long compile, a container build
# or a download involves no keystrokes, so an unconditional timer would suspend
# the machine in the middle of it. On battery that trade is worth making; on
# mains there is nothing to save and a real job to lose.
# ==============================================================================
set -uo pipefail

# Mains and USB-PD both count as plugged in; batteries expose no `online` node,
# so they are skipped by the readability test rather than needing a type filter.
on_external_power() {
    local d t o
    for d in /sys/class/power_supply/*/; do
        t="$(cat "${d}type" 2>/dev/null)" || continue
        [[ "$t" == "Mains" || "$t" == "USB" ]] || continue
        o="$(cat "${d}online" 2>/dev/null)" || continue
        [[ "$o" == "1" ]] && return 0
    done
    return 1
}

if on_external_power; then
    exit 0
fi

exec systemctl suspend
