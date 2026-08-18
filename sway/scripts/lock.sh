#!/usr/bin/env bash
# ==============================================================================
# CYBER NOIR // LOCK SCREEN
# ==============================================================================
# Locks the session over a SHARP WALLPAPER with the desktop reduced to a faint,
# unreadable ghost on top of it.
#
# Why the wallpaper is re-composited rather than just blurred
# ------------------------------------------------------------------------------
# grim hands back the frame the compositor already flattened. By that point the
# wallpaper and the window contents are one image -- and because the terminal is
# translucent, the wallpaper you can see through it is baked into the very pixels
# the text sits on. There is no layer left to separate, so "blur the text but not
# the wallpaper" cannot be done to a screenshot.
#
# So the wallpaper is put back underneath instead: swaybg's current image is read
# live (below), drawn sharp, and the blurred capture is blended over it at
# BLEND%. Because the terminal is mostly transparent, the capture is mostly
# wallpaper too -- the sharp copy wins, and the text dissolves rather than merely
# softening. What survives is window edges and haze: enough to read as a locked
# session, never enough to read as words.
#
# Why not swaylock-effects
# ------------------------------------------------------------------------------
# Upstream swaylock (1.8.x, what CachyOS ships) cannot blur or screenshot -- it
# only takes `-i <image>`. The effects fork can, but sits at 1.8.1 against
# upstream's 1.8.6, so it would mean a lagging fork of a security-critical
# component. Cost of doing it here instead: the real desktop stays visible for
# the ~0.4s the capture takes (grim alone is ~0.17s of that, and is the part that
# cannot be optimised away).
#
# Invariants
# ------------------------------------------------------------------------------
#   * It MUST end with the session locked. Every failure path falls through to a
#     plainer lock rather than returning unlocked -- a lock screen that silently
#     no-ops is worse than an ugly one.
#   * `-f` is required, not cosmetic. swayidle waits for its `before-sleep`
#     command to exit before releasing the sleep inhibitor, so a foreground
#     swaylock would hold off the suspend until somebody unlocked the machine.
#     swaylock forks only after the lock surface is up and the image is decoded.
#   * The snapshot is a picture of whatever was on screen, so it lives in
#     XDG_RUNTIME_DIR (tmpfs, user-only) at umask 077 and is deleted as soon as
#     swaylock has it in memory. It never touches the disk or the repo.
# ==============================================================================
set -uo pipefail

CONFIG="$HOME/.config/swaylock/config"
RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
LOCKFILE="${RUNTIME}/cyber-noir-lock.lock"

# How much of the blurred desktop shows through the sharp wallpaper, 0-100.
# 55 = wallpaper only, 70 = faint ghost, 85 = content clearly present.
BLEND=70

# Blur strength is the `-scale` value, NOT `-blur`: the sigma is applied to the
# shrunken frame, so the effective radius at full size is about 3 / (scale/100).
# `-scale` and `-resize` must stay in step (30/333.334, 40/250, 50/200) or the
# image comes out the wrong size.
BLUR_SCALE=30
BLUR_UP=333.334

SHOTS=()
IMAGE_ARGS=()

cleanup() { [[ ${#SHOTS[@]} -gt 0 ]] && rm -f -- "${SHOTS[@]}"; }
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Single instance
# ------------------------------------------------------------------------------
# The idle timeout, the `lock` event, the power menu and Super+Ctrl+L can all
# fire at once. flock serialises the racers; the pgrep check drops the ones that
# arrive when the screen is already locked.
exec 9>"$LOCKFILE"
flock -n 9 || exit 0
pgrep -x swaylock >/dev/null 2>&1 && exit 0

# ------------------------------------------------------------------------------
# Current wallpaper
# ------------------------------------------------------------------------------
# Read from the running swaybg rather than hardcoded, so it tracks
# wallpaper_rotator.sh instead of going stale the first time the wallpaper
# changes. /proc/PID/cmdline is NUL-separated, which is what makes this correct
# for the filenames containing spaces that are already in the wallpaper folder
# ("shi hao.png") -- parsing `pgrep -a` output would split those.
current_wallpaper() {
    local p prev arg
    for p in $(pgrep -x swaybg 2>/dev/null); do
        prev=""
        while IFS= read -r -d '' arg; do
            [[ "$prev" == "-i" ]] && { printf '%s' "$arg"; return 0; }
            prev="$arg"
        done < "/proc/$p/cmdline"
    done
    # swaybg not running (or started without -i): fall back to the rotator state.
    local state="${XDG_STATE_HOME:-$HOME/.local/state}/cyber-studio/wallpaper.state"
    [[ -r "$state" ]] && sed -n 's/^current=//p' "$state" | head -1
}

# ------------------------------------------------------------------------------
# Cached derivations
# ------------------------------------------------------------------------------
# Decoding the wallpaper and generating the vignette cost 273ms and 156ms -- more
# than half the total, and both produce a byte-identical result on every lock.
# They are cached in XDG_RUNTIME_DIR, which is tmpfs: the cache dies with the
# session, so a wallpaper swapped while logged out can never serve a stale frame.
# Cached as jpeg/png rather than miff because an uncompressed 1080p miff is ~8MB
# of RAM apiece and re-decoding a small jpeg is far cheaper than that trade.
#
# Neither file is sensitive -- one is a wallpaper already sitting on disk, the
# other a gradient. Only the screen capture is, and that is still deleted the
# moment swaylock has it.
CACHE_PREFIX="${RUNTIME}/cyber-noir-lock-cache"

wallpaper_base() {
    local src="$1" w="$2" h="$3" key out
    # mtime+size in the key: rotating to a different file, or editing one in
    # place, invalidates without needing to hash megabytes of pixels.
    key="$(stat -c '%Y-%s' "$src" 2>/dev/null)-${w}x${h}"
    out="${CACHE_PREFIX}-base-${key}.jpg"
    if [[ ! -s "$out" ]]; then
        # Drop bases for other wallpapers/sizes so tmpfs cannot accumulate one
        # file per wallpaper across a long uptime.
        rm -f -- "${CACHE_PREFIX}-base-"*.jpg 2>/dev/null
        ( umask 077; : >"$out" ) 2>/dev/null || return 1
        magick "$src" -resize "${w}x${h}^" -gravity center -extent "${w}x${h}" \
               -quality 95 "$out" 2>/dev/null || { rm -f -- "$out"; return 1; }
    fi
    printf '%s' "$out"
}

vignette() {
    local w="$1" h="$2" out="${CACHE_PREFIX}-vig-${w}x${h}.png"
    if [[ ! -s "$out" ]]; then
        ( umask 077; : >"$out" ) 2>/dev/null || return 1
        magick -size "${w}x${h}" radial-gradient:'#00000000'-'#00000048' \
               "$out" 2>/dev/null || { rm -f -- "$out"; return 1; }
    fi
    printf '%s' "$out"
}

# ------------------------------------------------------------------------------
# Capture, blur, and lay it over the sharp wallpaper -- one image per output
# ------------------------------------------------------------------------------
# Per output, not one spanning grab: with two monitors a single layout-wide
# capture would be letterboxed onto each of them by `--scaling fill`.
#
# Everything happens in ONE magick invocation, with grim's ppm read from stdin
# inside a group. The obvious version -- blur to a temp file, `identify` it for
# the size, composite in a second pass -- cost ~220ms more in process startups
# and in writing then re-reading an ~8MB uncompressed intermediate.
#
# Sizes therefore come from swaymsg rather than from the captured file. grim
# captures at the output's mode, so a 90/270 rotation swaps width and height;
# the final `-resize WxH!` on the capture is a cheap belt-and-braces alignment
# in case any of that is ever wrong, since `-composite` would otherwise offset
# a mismatched layer instead of fitting it.
#
# grim writes uncompressed ppm down the pipe -- asking it for png costs ~0.35s
# in compression for a frame about to be destroyed by a blur anyway. jpeg out:
# swaylock links gdk-pixbuf, so it reads jpeg fine and encodes far faster.
capture() {
    command -v grim   >/dev/null 2>&1 || return 1
    command -v magick >/dev/null 2>&1 || return 1
    command -v jq     >/dev/null 2>&1 || return 1

    local wall; wall="$(current_wallpaper)"
    [[ -n "$wall" && -r "$wall" ]] || wall=""

    local rows=() row o w h f base vig
    mapfile -t rows < <(swaymsg -t get_outputs 2>/dev/null | jq -r '
        .[] | select(.active) |
        if ((.transform // "normal") | test("^(90|270)"))
        then "\(.name) \(.current_mode.height) \(.current_mode.width)"
        else "\(.name) \(.current_mode.width) \(.current_mode.height)" end
    ' 2>/dev/null)
    [[ ${#rows[@]} -gt 0 ]] || return 1

    for row in "${rows[@]}"; do
        read -r o w h <<<"$row"
        [[ -n "${o:-}" && -n "${w:-}" && -n "${h:-}" ]] || return 1

        f="${RUNTIME}/cyber-noir-lock-${o}.jpg"
        ( umask 077; : >"$f" ) 2>/dev/null || return 1
        SHOTS+=("$f")

        base=""; vig=""
        if [[ -n "$wall" ]]; then
            base="$(wallpaper_base "$wall" "$w" "$h")" || base=""
            vig="$(vignette "$w" "$h")" || vig=""
        fi

        if [[ -n "$base" && -n "$vig" ]]; then
            grim -o "$o" -t ppm - 2>/dev/null \
              | magick "$base" \
                  \( ppm:- -scale ${BLUR_SCALE}% -blur 0x3 -resize ${BLUR_UP}% \
                     -resize "${w}x${h}!" \) \
                  -compose blend -define compose:args=${BLEND} -composite \
                  "$vig" -compose over -composite \
                  -quality 88 "$f" 2>/dev/null || return 1
        else
            # No readable wallpaper: plain blurred desktop, tinted so the
            # indicator still has something to sit against.
            grim -o "$o" -t ppm - 2>/dev/null \
              | magick ppm:- -scale ${BLUR_SCALE}% -blur 0x3 -resize ${BLUR_UP}% \
                  -fill '#090C14' -colorize 20% -quality 88 "$f" 2>/dev/null \
              || return 1
        fi
        [[ -s "$f" ]] || return 1

        IMAGE_ARGS+=(--image "${o}:${f}")
    done
}

if capture; then
    IMAGE_ARGS+=(--scaling fill)
else
    # Blank the half-built list so the fallback lock uses the wallpaper from the
    # config file instead of a torn or empty composite.
    IMAGE_ARGS=()
fi

# ------------------------------------------------------------------------------
# Lock -- degrading, never giving up
# ------------------------------------------------------------------------------
if ! swaylock -f --config "$CONFIG" "${IMAGE_ARGS[@]}"; then
    if ! swaylock -f --config "$CONFIG"; then
        swaylock -f --color 090C14
    fi
fi
