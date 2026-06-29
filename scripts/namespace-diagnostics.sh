#!/usr/bin/env bash
# namespace-diagnostics.sh — full READ-ONLY snapshot of a single namespace:
# every workload, its status, events, resource usage, quotas, limits, and
# network policies. The fastest way to triage "something in this namespace
# is broken."
#
# Usage: ./namespace-diagnostics.sh -n namespace [-o dir]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

NS=""; OUTDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n) NS="$2"; shift 2 ;;
    -o) OUTDIR="$2"; shift 2 ;;
    -h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done
[ -z "$NS" ] && { err "-n namespace is required"; exit 1; }

require_kubectl; check_context
$KUBECTL get ns "$NS" >/dev/null 2>&1 || { err "Namespace '$NS' not found."; exit 1; }
OUTDIR="${OUTDIR:-ns-$NS-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"

run_capture "$OUTDIR/all.txt"          "All workloads"          $KUBECTL get all -n "$NS" -o wide
run_capture "$OUTDIR/pods-wide.txt"    "Pods (wide, restarts)"  $KUBECTL get pods -n "$NS" -o wide
run_capture "$OUTDIR/events.txt"       "Events (sorted)"        \
  $KUBECTL get events -n "$NS" --sort-by=.lastTimestamp
run_capture "$OUTDIR/resourcequota.txt" "ResourceQuotas"        $KUBECTL get resourcequota -n "$NS" -o yaml
run_capture "$OUTDIR/limitrange.txt"   "LimitRanges"            $KUBECTL get limitrange -n "$NS" -o yaml
run_capture "$OUTDIR/configmaps.txt"   "ConfigMaps"             $KUBECTL get configmap -n "$NS"
run_capture "$OUTDIR/secrets.txt"      "Secrets (names only)"   $KUBECTL get secret -n "$NS"
run_capture "$OUTDIR/networkpolicies.txt" "NetworkPolicies"     $KUBECTL get networkpolicy -n "$NS" -o wide
run_capture "$OUTDIR/serviceaccounts.txt" "ServiceAccounts"     $KUBECTL get sa -n "$NS"
$KUBECTL top pods -n "$NS" >/dev/null 2>&1 && \
  run_capture "$OUTDIR/top-pods.txt"   "Pod resource usage"     $KUBECTL top pods -n "$NS"
ok "Namespace diagnostics for '$NS' written to ./$OUTDIR/"
warn "secrets.txt lists names only (no values) — but review before sharing."
