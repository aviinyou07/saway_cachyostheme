#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO WAYBAR // CPU PACKAGE TEMPERATURE
# ==============================================================================
# Polls every 5s, so it reads sysfs directly instead of shelling out to
# `sensors`. The old version spawned lm_sensors once, and a SECOND time whenever
# the first grep pattern missed -- 26ms a tick, ~7.5 minutes of CPU per day, to
# read one integer the kernel already exposes as a file.
#
# The hwmon index is not stable across boots (it depends on driver probe order),
# so the resolved path is cached in XDG_RUNTIME_DIR -- tmpfs, therefore
# rediscovered automatically on the next boot -- and revalidated by a plain
# readability test on every use.
#
# `sensors` is kept only as a last resort for hardware exposing none of the
# known driver names, so behaviour is unchanged on exotic machines.
# ==============================================================================
set -uo pipefail
shopt -s nullglob

CACHE="${XDG_RUNTIME_DIR:-/tmp}/cyber-noir-cputemp-path"

emit_unknown() { echo '{"text":"","class":"unknown"}'; exit 0; }

find_sensor() {
    local h name t label
    # Package-wide sensors first; these are the ones that mean "the CPU".
    for h in /sys/class/hwmon/hwmon*; do
        name="$(cat "$h/name" 2>/dev/null)" || continue
        case "$name" in
            coretemp|k10temp|zenpower) ;;
            *) continue ;;
        esac
        for t in "$h"/temp*_input; do
            label="$(cat "${t%_input}_label" 2>/dev/null)"
            case "$label" in
                "Package id 0"|Tctl|Tdie) printf '%s' "$t"; return 0 ;;
            esac
        done
        # Driver matched but no package label -- take its first reading.
        for t in "$h"/temp*_input; do printf '%s' "$t"; return 0; done
    done
    return 1
}

SENSOR=""
[[ -r "$CACHE" ]] && SENSOR="$(cat "$CACHE" 2>/dev/null)"
if [[ -z "$SENSOR" || ! -r "$SENSOR" ]]; then
    SENSOR="$(find_sensor)" || SENSOR=""
    [[ -n "$SENSOR" ]] && printf '%s' "$SENSOR" >"$CACHE" 2>/dev/null
fi

if [[ -n "$SENSOR" && -r "$SENSOR" ]]; then
    RAW="$(cat "$SENSOR" 2>/dev/null)"
    [[ "$RAW" =~ ^-?[0-9]+$ ]] || emit_unknown
    TEMP=$(( RAW / 1000 ))
else
    # Last resort: the original lm_sensors path, one invocation only.
    TEMP=$(sensors 2>/dev/null | grep -m1 -oP '^(Core 0|Package id 0|Tctl|Tdie):\s+\+\K[0-9]+')
    [[ -n "$TEMP" ]] || emit_unknown
fi

if   [[ "$TEMP" -ge 85 ]]; then CLASS="critical"
elif [[ "$TEMP" -ge 70 ]]; then CLASS="hot"
elif [[ "$TEMP" -ge 55 ]]; then CLASS="warm"
else CLASS="cool"; fi

printf '{"text":"󰔏 %s°","tooltip":"CPU: %s°C","class":"%s"}\n' "$TEMP" "$TEMP" "$CLASS"
