#!/usr/bin/env bash
# Ping Latency Module
MS=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | grep -oP 'time=\K[0-9.]+' | head -1 | cut -d. -f1)

[[ -z "$MS" ]] && { echo '{"text":"","class":"offline"}'; exit 0; }

if   [[ "$MS" -ge 150 ]]; then CLASS="high"
elif [[ "$MS" -ge 50  ]]; then CLASS="mid"
else CLASS="low"; fi

echo "{\"text\":\"󰓅 ${MS}ms\",\"tooltip\":\"Ping: ${MS}ms to 1.1.1.1\",\"class\":\"${CLASS}\"}"
