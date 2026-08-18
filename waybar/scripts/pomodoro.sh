#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO WAYBAR // POMODORO TIMER
# ==============================================================================
# waybar runs this once a SECOND, forever, whether or not a timer is going -- so
# every fork in here is paid 86,400 times a day. Two were removed:
#
#   * `date +%s` -> $EPOCHSECONDS, a bash 5 builtin, so reading the clock no
#     longer spawns a process.
#   * TEXT=$(printf ...) -> printf -v TEXT, so formatting no longer spawns a
#     subshell.
#
# State moved from /tmp/pomodoro_state to XDG_RUNTIME_DIR. The old path was a
# predictable name in a world-writable directory, which on a multi-user box lets
# anyone else create or clobber it; the runtime dir is user-only and clears
# itself at logout. A timer left running across a reboot is not worth keeping.
# ==============================================================================
set -uo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/cyber-noir-pomodoro"
WORK_TIME=1500   # 25 minutes
BREAK_TIME=300   # 5 minutes

[[ -f "$STATE_FILE" ]] || echo "STOPPED|WORK|0" > "$STATE_FILE"
IFS='|' read -r STATUS MODE START_TIME < "$STATE_FILE"

# Guard against a truncated or hand-edited state file: without this a
# non-numeric START_TIME makes every later $(( )) a fatal arithmetic error.
[[ "${START_TIME:-}" =~ ^-?[0-9]+$ ]] || { STATUS=STOPPED; MODE=WORK; START_TIME=0; }

case "${1:-}" in
    toggle)
        if [[ "$STATUS" == "STOPPED" ]]; then
            echo "RUNNING|$MODE|$EPOCHSECONDS" > "$STATE_FILE"
        elif [[ "$STATUS" == "PAUSED" ]]; then
            # While PAUSED, START_TIME holds REMAINING seconds, so resuming
            # means back-dating the start by however much has already elapsed.
            DURATION=$WORK_TIME
            [[ "$MODE" == "BREAK" ]] && DURATION=$BREAK_TIME
            echo "RUNNING|$MODE|$(( EPOCHSECONDS - (DURATION - START_TIME) ))" > "$STATE_FILE"
        else
            DURATION=$WORK_TIME
            [[ "$MODE" == "BREAK" ]] && DURATION=$BREAK_TIME
            echo "PAUSED|$MODE|$(( DURATION - (EPOCHSECONDS - START_TIME) ))" > "$STATE_FILE"
        fi
        exit 0 ;;
    reset) echo "STOPPED|WORK|0"           > "$STATE_FILE"; exit 0 ;;
    break) echo "RUNNING|BREAK|$EPOCHSECONDS" > "$STATE_FILE"; exit 0 ;;
    work)  echo "RUNNING|WORK|$EPOCHSECONDS"  > "$STATE_FILE"; exit 0 ;;
esac

TEXT="󱎫 25:00"
CLASS="stopped"
TOOLTIP="Pomodoro: Stopped\nLeft click: Start/Pause\nRight click: Reset\nMiddle click: Toggle Work/Break"

if [[ "$STATUS" == "RUNNING" ]]; then
    DURATION=$WORK_TIME
    [[ "$MODE" == "BREAK" ]] && DURATION=$BREAK_TIME
    REMAINING=$(( DURATION - (EPOCHSECONDS - START_TIME) ))

    if (( REMAINING <= 0 )); then
        if [[ "$MODE" == "WORK" ]]; then
            notify-send -u critical -t 10000 "🍅 Pomodoro" "Work session complete! Take a break."
            echo "STOPPED|BREAK|0" > "$STATE_FILE"
        else
            notify-send -u critical -t 10000 "🍅 Pomodoro" "Break over! Back to work."
            echo "STOPPED|WORK|0" > "$STATE_FILE"
        fi
        TEXT="󱎫 00:00"; CLASS="finished"
    else
        printf -v TEXT '󱎫 %02d:%02d' $(( REMAINING / 60 )) $(( REMAINING % 60 ))
        if [[ "$MODE" == "WORK" ]]; then
            CLASS="running-work";  TOOLTIP="Work Mode\n$TEXT remaining"
        else
            CLASS="running-break"; TOOLTIP="Break Mode\n$TEXT remaining"
        fi
    fi
elif [[ "$STATUS" == "PAUSED" ]]; then
    printf -v TEXT '󱎫 %02d:%02d' $(( START_TIME / 60 )) $(( START_TIME % 60 ))
    CLASS="paused"; TOOLTIP="Paused ($MODE Mode)\n$TEXT remaining"
elif [[ "$STATUS" == "STOPPED" && "$MODE" == "BREAK" ]]; then
    TEXT="󱎫 05:00"; CLASS="stopped-break"; TOOLTIP="Pomodoro: Break Time (Stopped)"
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
