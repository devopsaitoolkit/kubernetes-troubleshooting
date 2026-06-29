#!/usr/bin/env bash
# collect-cluster-diagnostics.sh — gather a broad, READ-ONLY snapshot of a
# cluster's health into a timestamped directory you can attach to an incident.
#
# Usage:
#   ./collect-cluster-diagnostics.sh [-n namespace] [-o output-dir]
#
# Collects: versions, nodes, component health, events, resource usage, and a
# per-namespace object inventory. Never modifies the cluster.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

NAMESPACE=""
OUTDIR="$OUTDIR_DEFAULT"
while getopts ":n:o:h" opt; do
  case "$opt" in
    n) NAMESPACE="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "Unknown option"; exit 1 ;;
  esac
done

require_kubectl
check_context
mkdir -p "$OUTDIR"
info "Writing diagnostics to ./$OUTDIR/"

run_capture "$OUTDIR/00-versions.txt"        "Client & server versions"      $KUBECTL version
run_capture "$OUTDIR/01-cluster-info.txt"    "Cluster endpoints"             $KUBECTL cluster-info
run_capture "$OUTDIR/02-nodes-wide.txt"      "Nodes (wide)"                  $KUBECTL get nodes -o wide
run_capture "$OUTDIR/03-nodes-describe.txt"  "Node details + conditions"     $KUBECTL describe nodes
run_capture "$OUTDIR/04-componentstatuses.txt" "Control plane component status" $KUBECTL get componentstatuses
run_capture "$OUTDIR/05-api-resources.txt"   "Served API resources"          $KUBECTL api-resources
run_capture "$OUTDIR/06-events-all.txt"      "Recent events (all namespaces)" \
  $KUBECTL get events --all-namespaces --sort-by=.lastTimestamp
run_capture "$OUTDIR/07-pods-not-running.txt" "Pods not in Running/Succeeded" \
  $KUBECTL get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded -o wide

if command -v "$KUBECTL" >/dev/null && $KUBECTL top nodes >/dev/null 2>&1; then
  run_capture "$OUTDIR/08-top-nodes.txt"     "Node resource usage"           $KUBECTL top nodes
  run_capture "$OUTDIR/09-top-pods.txt"      "Pod resource usage (all ns)"   $KUBECTL top pods --all-namespaces
else
  warn "metrics-server unavailable; skipping 'kubectl top'."
fi

if [ -n "$NAMESPACE" ]; then
  run_capture "$OUTDIR/10-ns-$NAMESPACE-all.txt" "All objects in $NAMESPACE" \
    $KUBECTL get all -n "$NAMESPACE" -o wide
else
  run_capture "$OUTDIR/10-namespaces.txt"    "Namespaces"                    $KUBECTL get namespaces
fi

ok "Done. Review ./$OUTDIR/ and attach it to your incident ticket."
warn "Diagnostics may contain sensitive names/IPs — review before sharing externally."
