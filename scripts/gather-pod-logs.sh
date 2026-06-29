#!/usr/bin/env bash
# gather-pod-logs.sh — collect logs + describe for pods in a namespace
# (READ-ONLY). Captures current and previous (--previous) container logs,
# which are essential for CrashLoopBackOff and OOMKilled investigations.
#
# Usage: ./gather-pod-logs.sh -n namespace [-l label-selector] [-o dir] [--tail N]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

NAMESPACE=""; SELECTOR=""; OUTDIR=""; TAIL="2000"
while [ $# -gt 0 ]; do
  case "$1" in
    -n) NAMESPACE="$2"; shift 2 ;;
    -l) SELECTOR="$2"; shift 2 ;;
    -o) OUTDIR="$2"; shift 2 ;;
    --tail) TAIL="$2"; shift 2 ;;
    -h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done
[ -z "$NAMESPACE" ] && { err "-n namespace is required"; exit 1; }

require_kubectl; check_context
OUTDIR="${OUTDIR:-podlogs-$NAMESPACE-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"

SEL=(); [ -n "$SELECTOR" ] && SEL=(-l "$SELECTOR")
mapfile -t PODS < <($KUBECTL get pods -n "$NAMESPACE" "${SEL[@]}" -o name 2>/dev/null)
[ "${#PODS[@]}" -eq 0 ] && { warn "No pods matched."; exit 0; }
info "Found ${#PODS[@]} pod(s) in $NAMESPACE"

for p in "${PODS[@]}"; do
  name="${p#pod/}"
  run_capture "$OUTDIR/$name.describe.txt" "describe $name" \
    $KUBECTL describe "$p" -n "$NAMESPACE"
  run_capture "$OUTDIR/$name.logs.txt" "logs $name (all containers)" \
    $KUBECTL logs "$p" -n "$NAMESPACE" --all-containers --tail="$TAIL"
  # Previous logs only exist after a restart; ignore failures.
  $KUBECTL logs "$p" -n "$NAMESPACE" --all-containers --previous --tail="$TAIL" \
    > "$OUTDIR/$name.previous.txt" 2>/dev/null \
    && info "Captured previous logs for $name" \
    || rm -f "$OUTDIR/$name.previous.txt"
done
ok "Logs written to ./$OUTDIR/"
