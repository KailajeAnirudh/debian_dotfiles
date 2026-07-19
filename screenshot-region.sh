#!/usr/bin/env bash
#
# screenshot-region.sh — Windows "Snip & Sketch" style region capture for i3/X11
#
# Compositor-safe design:
#   Instead of maim -s (which captures the screen LIVE and bakes in any
#   picom/compositor blur or dim triggered by the selection overlay), this:
#     1. Grabs a CLEAN full-screen image the instant the key is pressed.
#     2. Uses slop ONLY to read the selection rectangle's coordinates.
#     3. Crops the region out of the clean image — so no blur ever reaches
#        the output, no matter what the compositor does during selection.
#
# Then it saves a timestamped PNG, copies it to the clipboard, and notifies.
#
# Dependencies: maim, slop, imagemagick (convert), xclip, libnotify (notify-send)
#
# Press Escape or right-click during selection to cancel — nothing is saved.

set -euo pipefail

# --- Config -----------------------------------------------------------------
SCREENSHOT_DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
FILENAME="screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"
TMP_FULL="$(mktemp --suffix=.png)"
cleanup() { rm -f "$TMP_FULL"; }
trap cleanup EXIT

# --- Dependency check -------------------------------------------------------
missing=()
for cmd in maim slop convert xclip; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
    msg="Missing: ${missing[*]}. Install with: sudo apt install maim slop imagemagick xclip"
    command -v notify-send >/dev/null 2>&1 && notify-send "Screenshot tool" "$msg"
    echo "$msg" >&2
    exit 1
fi

mkdir -p "$SCREENSHOT_DIR"

# --- 1. Clean full-screen grab (before any overlay is drawn) ----------------
maim -u "$TMP_FULL"

# --- 2. Selection geometry only (overlay/blur here is irrelevant) -----------
# slop prints "X Y W H" with NO trailing newline, and exits non-zero if the
# user cancels. Capturing into a variable lets slop's own exit code signal
# cancellation; the here-string then gives `read` the newline it needs so it
# doesn't falsely report EOF-without-delimiter as a failure.
GEOMETRY="$(slop -f "%x %y %w %h" 2>/dev/null)" || exit 0   # cancelled
[[ -z "$GEOMETRY" ]] && exit 0
read -r X Y W H <<< "$GEOMETRY"

# Ignore an empty/zero selection (a stray click).
if [[ -z "${W:-}" || -z "${H:-}" || "$W" -le 0 || "$H" -le 0 ]]; then
    exit 0
fi

# --- 3. Crop the region out of the CLEAN image ------------------------------
convert "$TMP_FULL" -crop "${W}x${H}+${X}+${Y}" +repage "$FILEPATH"

# --- Clipboard --------------------------------------------------------------
# xclip serves the clipboard from its OWN process memory, so it must keep
# running after this script exits. Under i3's `exec`, a plain xclip call gets
# reaped on exit and the clipboard ends up empty. setsid -f fully detaches it
# into its own session so it survives and keeps serving paste requests.
setsid -f xclip -selection clipboard -t image/png -i "$FILEPATH" >/dev/null 2>&1

# --- Notify -----------------------------------------------------------------
if command -v notify-send >/dev/null 2>&1; then
    notify-send -i "$FILEPATH" "Screenshot captured" "Copied to clipboard\n$FILEPATH"
fi
