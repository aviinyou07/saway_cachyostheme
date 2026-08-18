#!/usr/bin/env bash
# Pomodoro Timer Module for Waybar
# Maintains state in /tmp/pomodoro_state

STATE_FILE="/tmp/pomodoro_state"
WORK_TIME=1500 # 25 minutes in seconds
BREAK_TIME=300 # 5 minutes in seconds

# Initialize state if not exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "STOPPED|WORK|0" > "$STATE_FILE"
fi

IFS='|' read -r STATUS MODE START_TIME < "$STATE_FILE"

# Handle actions (start/pause/reset) passed as arguments
case "$1" in
    toggle)
        if [[ "$STATUS" == "STOPPED" || "$STATUS" == "PAUSED" ]]; then
            # Start or resume
            if [[ "$STATUS" == "STOPPED" ]]; then
                echo "RUNNING|$MODE|$(date +%s)" > "$STATE_FILE"
            else
                # Resume from pause: adjust start time by the pause duration
                # In PAUSED state, START_TIME actually holds the remaining seconds
                NEW_START=$(($(date +%s) - ($WORK_TIME - $START_TIME)))
                [[ "$MODE" == "BREAK" ]] && NEW_START=$(($(date +%s) - ($BREAK_TIME - $START_TIME)))
                echo "RUNNING|$MODE|$NEW_START" > "$STATE_FILE"
            fi
        else
            # Pause
            CURRENT_TIME=$(date +%s)
            ELAPSED=$((CURRENT_TIME - START_TIME))
            DURATION=$WORK_TIME
            [[ "$MODE" == "BREAK" ]] && DURATION=$BREAK_TIME
            REMAINING=$((DURATION - ELAPSED))
            echo "PAUSED|$MODE|$REMAINING" > "$STATE_FILE"
        fi
        exit 0
        ;;
    reset)
        echo "STOPPED|WORK|0" > "$STATE_FILE"
        exit 0
        ;;
    break)
        echo "RUNNING|BREAK|$(date +%s)" > "$STATE_FILE"
        exit 0
        ;;
    work)
        echo "RUNNING|WORK|$(date +%s)" > "$STATE_FILE"
        exit 0
        ;;
esac

# Calculate display output
TEXT="󱎫 25:00"
CLASS="stopped"
TOOLTIP="Pomodoro: Stopped\nLeft click: Start/Pause\nRight click: Reset\nMiddle click: Toggle Work/Break"

if [[ "$STATUS" == "RUNNING" ]]; then
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [[ "$MODE" == "WORK" ]]; then
        REMAINING=$((WORK_TIME - ELAPSED))
        if [[ $REMAINING -le 0 ]]; then
            # Time's up! Send notification and switch to break
            notify-send -u critical -t 10000 "🍅 Pomodoro" "Work session complete! Take a break."
            echo "STOPPED|BREAK|0" > "$STATE_FILE"
            TEXT="󱎫 00:00"
            CLASS="finished"
        else
            M=$((REMAINING / 60))
            S=$((REMAINING % 60))
            TEXT=$(printf "󱎫 %02d:%02d" $M $S)
            CLASS="running-work"
            TOOLTIP="Work Mode\n$TEXT remaining"
        fi
    elif [[ "$MODE" == "BREAK" ]]; then
        REMAINING=$((BREAK_TIME - ELAPSED))
        if [[ $REMAINING -le 0 ]]; then
            notify-send -u critical -t 10000 "🍅 Pomodoro" "Break over! Back to work."
            echo "STOPPED|WORK|0" > "$STATE_FILE"
            TEXT="󱎫 00:00"
            CLASS="finished"
        else
            M=$((REMAINING / 60))
            S=$((REMAINING % 60))
            TEXT=$(printf "󱎫 %02d:%02d" $M $S)
            CLASS="running-break"
            TOOLTIP="Break Mode\n$TEXT remaining"
        fi
    fi
elif [[ "$STATUS" == "PAUSED" ]]; then
    M=$((START_TIME / 60))
    S=$((START_TIME % 60))
    TEXT=$(printf "󱎫 %02d:%02d" $M $S)
    CLASS="paused"
    TOOLTIP="Paused ($MODE Mode)\n$TEXT remaining"
elif [[ "$STATUS" == "STOPPED" ]]; then
    if [[ "$MODE" == "BREAK" ]]; then
        TEXT="󱎫 05:00"
        CLASS="stopped-break"
        TOOLTIP="Pomodoro: Break Time (Stopped)"
    fi
fi

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
