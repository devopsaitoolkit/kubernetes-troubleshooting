#!/usr/bin/env bash
# export-events.sh — export sorted cluster events (READ-ONLY).
# Usage: ./export-events.sh [-n namespace] [-o file] [--warnings-only]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

NAMESPACE=""; OUT=""; WARN_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    -n) NAMESPACE="$2"; shift 2 ;;
    -o) OUT="$2"; shift 2 ;;
    --warnings-only) WARN_ONLY=1; shift ;;
    -h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done

require_kubectl; check_context
SCOPE=(--all-namespaces); [ -n "$NAMESPACE" ] && SCOPE=(-n "$NAMESPACE")
FILTER=(); [ "$WARN_ONLY" = 1 ] && FILTER=(--field-selector type=Warning)
OUT="${OUT:-events-$(date +%Y%m%d-%H%M%S).txt}"

info "Exporting events to $OUT"
$KUBECTL get events "${SCOPE[@]}" "${FILTER[@]}" --sort-by=.lastTimestamp -o wide | tee "$OUT"
ok "Wrote $OUT"
