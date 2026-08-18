#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO WAYBAR // GIT BRANCH OF THE FOCUSED WINDOW
# ==============================================================================
# Reports the branch of the repository the FOCUSED window is working in, or
# nothing at all.
#
# The previous version fell back to scanning ~/Desktop, ~/Projects and this repo
# whenever detection failed, so the bar confidently displayed a branch that had
# nothing to do with what you were looking at. A status bar that shows a
# plausible-but-wrong value is worse than one that shows nothing.
#
# It also shelled out to python3 on every tick (~88 ms, every 10 s). This uses
# jq, which waybar already depends on for JSON anyway.
# ==============================================================================
set -uo pipefail

emit_none() { printf '{"text": "", "class": "none"}\n'; exit 0; }

command -v swaymsg >/dev/null 2>&1 || emit_none
command -v jq      >/dev/null 2>&1 || emit_none

# PID of the focused container. `..` descends the whole tree including floats.
PID=$(swaymsg -t get_tree 2>/dev/null \
      | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | .pid // empty' \
      | head -1)

[[ -n "${PID:-}" ]] || emit_none

CWD=$(readlink -f "/proc/$PID/cwd" 2>/dev/null) || emit_none
[[ -n "$CWD" && -d "$CWD" ]] || emit_none

# git already walks upward to find the repo root -- no manual parent loop needed.
BRANCH=$(git -C "$CWD" --no-optional-locks symbolic-ref --quiet --short HEAD 2>/dev/null) \
  || BRANCH=$(git -C "$CWD" --no-optional-locks rev-parse --short HEAD 2>/dev/null) \
  || emit_none

[[ -n "${BRANCH:-}" ]] || emit_none

REPO_NAME=$(basename "$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)

DISPLAY_BRANCH="$BRANCH"
(( ${#BRANCH} > 20 )) && DISPLAY_BRANCH="${BRANCH:0:20}…"

# jq -n builds the JSON, so branch names containing quotes or backslashes cannot
# corrupt the payload the way printf-built JSON could.
jq -cn --arg t "⎇ $DISPLAY_BRANCH" \
       --arg b "$BRANCH" \
       --arg r "${REPO_NAME:-unknown}" \
       '{text: $t, tooltip: ("Repository: " + $r + "\nBranch: " + $b), class: "active"}'
