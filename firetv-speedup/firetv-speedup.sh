#!/usr/bin/env bash
# firetv-speedup.sh — make an Amazon Fire TV feel faster over ADB (no root).
#
# Usage:
#   ./firetv-speedup.sh <fire-tv-ip> [command]
#
# Commands:
#   boost    (default) faster animations, disable telemetry/ad services,
#            clear caches, stop background apps
#   clean    clear caches and stop background apps only (safe to run weekly)
#   status   show free storage, free memory and the biggest memory users
#   restore  undo everything `boost` changed
#
# Every change is reversible with `restore`, and nothing is uninstalled.

set -euo pipefail

# Services that phone home or show ads and run in the background all the time.
# Disabling them frees memory and CPU; none are needed to watch anything.
BLOAT_PACKAGES=(
  com.amazon.device.crashmanager   # crash report uploader
  com.amazon.logan                 # usage logging
  com.amazon.client.metrics        # metrics uploader
  com.amazon.kso                   # sponsored screensaver / home-screen ads
)

ANIMATION_SETTINGS=(window_animation_scale transition_animation_scale animator_duration_scale)
FAST_ANIMATION_SCALE=0.5
DEFAULT_ANIMATION_SCALE=1.0

die() { echo "Error: $*" >&2; exit 1; }
step() { printf '\n==> %s\n' "$*"; }

[[ $# -ge 1 ]] || { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

HOST="$1"
COMMAND="${2:-boost}"
[[ "$HOST" == *:* ]] || HOST="$HOST:5555"
case "$COMMAND" in
  boost|clean|status|restore) ;;
  *) die "unknown command '$COMMAND' (use boost, clean, status or restore)" ;;
esac

command -v adb >/dev/null 2>&1 ||
  die "adb not found. Install Android platform-tools: https://developer.android.com/tools/releases/platform-tools"

sh_tv() { adb -s "$HOST" shell "$@" | tr -d '\r'; }

connect() {
  step "Connecting to $HOST"
  adb connect "$HOST" >/dev/null || true
  local state
  state="$(adb -s "$HOST" get-state 2>/dev/null || true)"
  if [[ "$state" != "device" ]]; then
    die "could not connect to $HOST (state: ${state:-none}).
  - Is ADB debugging on? Settings > My Fire TV > Developer options > ADB debugging
  - Did you accept the 'Allow USB debugging?' prompt on the TV? Run this again after accepting.
  - Is the IP right? Settings > My Fire TV > About > Network"
  fi
  echo "Connected: $(sh_tv getprop ro.product.model) ($(sh_tv getprop ro.build.version.name))"
}

set_animations() {
  local scale="$1" key
  step "Setting animation speed to ${scale}x"
  for key in "${ANIMATION_SETTINGS[@]}"; do
    sh_tv settings put global "$key" "$scale"
  done
}

disable_bloat() {
  local pkg out
  step "Disabling background telemetry and ad services"
  for pkg in "${BLOAT_PACKAGES[@]}"; do
    if ! sh_tv pm list packages "$pkg" | grep -qx "package:$pkg"; then
      echo "  - $pkg: not on this device, skipped"
      continue
    fi
    out="$(sh_tv pm disable-user --user 0 "$pkg" 2>&1 || true)"
    if [[ "$out" == *"disabled"* ]]; then
      echo "  - $pkg: disabled"
    else
      echo "  - $pkg: blocked by Fire OS, skipped"
    fi
  done
}

enable_bloat() {
  local pkg
  step "Re-enabling services"
  for pkg in "${BLOAT_PACKAGES[@]}"; do
    if sh_tv pm enable "$pkg" >/dev/null 2>&1; then
      echo "  - $pkg: enabled"
    else
      echo "  - $pkg: not on this device, skipped"
    fi
  done
}

clean() {
  step "Clearing app caches"
  sh_tv pm trim-caches 999G
  echo "Done."
  step "Stopping background apps"
  sh_tv am kill-all
  echo "Done."
}

status() {
  step "Storage"
  sh_tv df -h /data | awk 'NR==1 || /\/data/'
  step "Memory"
  sh_tv cat /proc/meminfo | grep -E '^(MemTotal|MemAvailable):' |
    awk '{printf "%-14s %6d MB\n", $1, $2/1024}'
  step "Top 10 apps by memory"
  sh_tv dumpsys meminfo |
    sed -n '/Total PSS by process:/,/^$/p' | sed '1d;/^$/d' | head -10
}

connect
case "$COMMAND" in
  boost)
    set_animations "$FAST_ANIMATION_SCALE"
    disable_bloat
    clean
    status
    printf '\nAll done. Restart the Fire TV (Settings > My Fire TV > Restart) for the best result.\n'
    ;;
  clean)   clean; status ;;
  status)  status ;;
  restore)
    set_animations "$DEFAULT_ANIMATION_SCALE"
    enable_bloat
    printf '\nRestored. Restart the Fire TV to finish.\n'
    ;;
esac
