#!/usr/bin/env bash
# Updates Counter Module
# Checks pacman and AUR updates
updates=$(checkupdates 2>/dev/null | wc -l)
aur_updates=$(yay -Qua 2>/dev/null | wc -l)

total=$((updates + aur_updates))

if [[ "$total" -eq 0 ]]; then
    echo '{"text": "", "class": "updated"}'
    exit 0
fi

if [[ "$total" -ge 20 ]]; then
    CLASS="critical"
elif [[ "$total" -ge 5 ]]; then
    CLASS="warning"
else
    CLASS="pending"
fi

printf '{"text": "󰏗 %s", "tooltip": "Pending Updates: %s\\nPacman: %s\\nAUR: %s", "class": "%s"}\n' \
    "$total" "$total" "$updates" "$aur_updates" "$CLASS"
