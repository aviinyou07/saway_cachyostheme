#!/usr/bin/env bash
# Updates Counter Module
# Checks pacman and AUR updates
# install.sh prefers paru and only falls back to yay, so hardcoding `yay` here
# meant that on a paru machine this silently reported 0 AUR updates forever --
# a status bar confidently showing "up to date" when it had not checked.
AUR_HELPER=""
for _h in paru yay; do
    command -v "$_h" >/dev/null 2>&1 && { AUR_HELPER="$_h"; break; }
done

updates=$(checkupdates 2>/dev/null | wc -l)
if [[ -n "$AUR_HELPER" ]]; then
    aur_updates=$("$AUR_HELPER" -Qua 2>/dev/null | wc -l)
else
    aur_updates=0
fi

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
