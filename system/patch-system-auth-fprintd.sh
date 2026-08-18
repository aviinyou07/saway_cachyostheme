#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // SYSTEM-WIDE FINGERPRINT AUTHENTICATION
# ==============================================================================
# Patches pam_fprintd into /etc/pam.d/system-auth -- the single stack that
# sudo, polkit-1, sddm, login (and therefore swaylock) and su all `include`.
# Editing it once is what makes the reader answer EVERY password prompt rather
# than just the lock screen.
#
# ------------------------------------------------------------------------------
# Why a patch script, when everything else under system/ is a shipped file
# ------------------------------------------------------------------------------
# system-auth is owned by the `pambase` package and its contents change between
# releases. Dropping a frozen snapshot over it would silently revert unrelated
# upstream PAM changes, and a stale auth stack is the kind of breakage you only
# discover when you can no longer log in. So this edits in place, and only
# after confirming the stack still has the shape it expects.
#
# ------------------------------------------------------------------------------
# Why an explicit jump instead of the obvious `sufficient`
# ------------------------------------------------------------------------------
#     auth  sufficient  pam_fprintd.so
# short-circuits out of the stack the moment the finger matches -- which skips
# the `pam_env.so` and `pam_faillock.so authsucc` lines further down. That
# yields a session with /etc/environment never applied and a failed-login
# counter that never resets, both only on fingerprint logins, which is a
# miserable thing to debug later.
#
# `[success=3 default=ignore]` jumps exactly over pam_systemd_home, pam_unix
# and faillock's authfail, landing on pam_permit -- so pam_env and authsucc
# still run. That literal 3 is why the shape check below is not optional: if
# pambase ever reorders the stack the offset would land somewhere arbitrary.
#
# Fails safe in every direction. `default=ignore` means an absent reader, an
# unenrolled user or a timeout falls straight through to the password prompt.
# ==============================================================================
set -euo pipefail

TARGET=/etc/pam.d/system-auth
SUDO_PAM=/etc/pam.d/sudo
MARKER='pam_fprintd.so'
BACKUP_DIR="${1:-/root/cyber-noir-pam-backup-$(date +%Y%m%d-%H%M%S)}"

[[ $EUID -eq 0 ]] || { echo "must run as root" >&2; exit 1; }

if [[ ! -f /usr/lib/security/pam_fprintd.so ]]; then
    echo "pam_fprintd.so not installed; refusing to reference a missing module." >&2
    exit 0
fi

if grep -q "$MARKER" "$TARGET"; then
    echo "system-auth already carries pam_fprintd; nothing to do."
else
    # Verify the three modules the jump skips are still in the expected order.
    #
    # Match on real module lines (^auth / ^-auth) rather than simply taking the
    # next three lines of the file: pambase ships two comment lines directly
    # after the preauth entry, and a naive `grep -A3` counts those as modules
    # and never sees the stack it is meant to be checking. PAM itself ignores
    # comments, so they do not affect the jump offset -- only the check.
    mapfile -t after < <(sed -n '/pam_faillock\.so.*preauth/,$p' "$TARGET" \
        | tail -n +2 | grep -E '^-?auth' | head -3)
    if [[ ${#after[@]} -ne 3 ]] \
       || [[ ${after[0]} != *pam_systemd_home.so* ]] \
       || [[ ${after[1]} != *pam_unix.so* ]] \
       || [[ ${after[2]} != *pam_faillock.so*authfail* ]]; then
        echo "system-auth does not have the expected stack shape -- pambase may have" >&2
        echo "changed it. Refusing to insert a jump whose offset is no longer correct." >&2
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"
    cp -a "$TARGET" "$BACKUP_DIR/system-auth.bak"
    sed -i '/pam_faillock\.so.*preauth/a auth       [success=3 default=ignore]  pam_fprintd.so       timeout=10' "$TARGET"
    echo "Patched $TARGET (backup: $BACKUP_DIR/system-auth.bak)"
fi

# CachyOS's chwd drops its own `auth sufficient pam_fprintd.so` into /etc/pam.d/sudo.
# Left in place alongside the system-auth entry it asks for a finger twice: once
# there, then again on fall-through -- so a failed read costs two full timeouts
# before the password prompt appears.
if grep -q 'chwd-fprintd' "$SUDO_PAM" 2>/dev/null; then
    mkdir -p "$BACKUP_DIR"
    cp -a "$SUDO_PAM" "$BACKUP_DIR/sudo.bak"
    sed -i '/chwd-fprintd/d' "$SUDO_PAM"
    echo "Removed chwd's duplicate pam_fprintd from $SUDO_PAM"
fi
