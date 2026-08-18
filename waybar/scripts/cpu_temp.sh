#!/usr/bin/env bash
# CPU Temperature Module
TEMP=$(sensors 2>/dev/null | grep -E "^Core 0:|^Package id 0:" | grep -oP '\+\K[0-9]+' | head -1)
[[ -z "$TEMP" ]] && TEMP=$(sensors 2>/dev/null | grep -oP '\+\K[0-9]+(?=\.\d+°C)' | head -1)
[[ -z "$TEMP" ]] && { echo '{"text":"","class":"unknown"}'; exit 0; }

if   [[ "$TEMP" -ge 85 ]]; then CLASS="critical"
elif [[ "$TEMP" -ge 70 ]]; then CLASS="hot"
elif [[ "$TEMP" -ge 55 ]]; then CLASS="warm"
else CLASS="cool"; fi

echo "{\"text\":\"󰔏 ${TEMP}°\",\"tooltip\":\"CPU: ${TEMP}°C\",\"class\":\"${CLASS}\"}"
