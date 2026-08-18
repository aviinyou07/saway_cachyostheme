#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // OPEN A RESIDENT APP
# ==============================================================================
# Activates one of the GTK apps over D-Bus instead of starting a new process.
#
# A Python GTK4 process needs ~1.45s to reach its first frame on this machine --
# interpreter, pygobject and GTK init, measured with an empty window, so it is a
# floor rather than something tunable. Spending it on every click is what made
# these feel like they opened "very very late". The apps are started once at
# login with --daemon and simply woken here: measured 27ms for the clipboard and
# ~200ms for networks, which additionally refreshes its list on the way up.
#
# The fallback matters: if the daemon is not running -- it crashed, or sway was
# reloaded oddly -- this starts the app the slow way rather than doing nothing.
# A launcher that silently no-ops is worse than a slow one.
# ==============================================================================
set -uo pipefail

APP_ID="${1:?usage: open-app.sh <app-id> <script>}"
SCRIPT="${2:?usage: open-app.sh <app-id> <script>}"

# org.freedesktop.Application object paths are the id with dots as slashes.
OBJ="/${APP_ID//./\/}"

# ActivateAction "open", not Activate. Activation is what a fresh `--daemon`
# launch triggers too, so using it here would mean a sway reload popped the
# window open; the explicit action only ever fires from a real request.
if gdbus call --session --dest "$APP_ID" --object-path "$OBJ" \
        --method org.freedesktop.Application.ActivateAction "open" "[]" "{}" \
        >/dev/null 2>&1; then
    exit 0
fi

exec "$SCRIPT"
