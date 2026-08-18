#!/usr/bin/env bash
# ==============================================================================
# ANTIGRAVITY LAUNCHER — SINGLETON LOCK CLEANER
# ==============================================================================
# Cleans up stale Electron singleton lock files before launching Antigravity.
# This prevents the "won't reopen after closing" bug caused by leftover lock
# files in ~/.config/Antigravity/ from a previous session or crash.
# ==============================================================================

ANTIGRAVITY_DATA="${HOME}/.config/Antigravity"
ANTIGRAVITY_BIN="/opt/antigravity/antigravity"

# Only clean locks if Antigravity is NOT currently running
if ! pgrep -x "antigravity" > /dev/null 2>&1; then
    # Remove stale Electron singleton files
    rm -f "${ANTIGRAVITY_DATA}/SingletonLock" \
          "${ANTIGRAVITY_DATA}/SingletonCookie" \
          "${ANTIGRAVITY_DATA}/SingletonSocket" \
          /tmp/scoped_dir*/SingletonSocket 2>/dev/null || true
fi

# Launch Antigravity with Wayland native rendering
exec "${ANTIGRAVITY_BIN}" \
    --enable-features=WaylandWindowDecorations \
    --ozone-platform-hint=auto \
    "$@"
