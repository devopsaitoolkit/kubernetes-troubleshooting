#!/usr/bin/env bash
# gather-node-info.sh — collect node health, conditions, capacity, taints, and
# the pods scheduled on each node (READ-ONLY). Useful for NodeNotReady,
# DiskPressure, MemoryPressure, and eviction investigations.
#
# Usage: ./gather-node-info.sh [-N node] [-o dir]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

NODE=""; OUTDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -N) NODE="$2"; shift 2 ;;
    -o) OUTDIR="$2"; shift 2 ;;
    -h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done

require_kubectl; check_context
OUTDIR="${OUTDIR:-nodeinfo-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"

if [ -n "$NODE" ]; then NODES=("$NODE"); else
  mapfile -t NODES < <($KUBECTL get nodes -o name | sed 's#node/##'); fi

run_capture "$OUTDIR/nodes-wide.txt"  "Nodes (wide)" $KUBECTL get nodes -o wide
$KUBECTL top nodes >/dev/null 2>&1 && \
  run_capture "$OUTDIR/top-nodes.txt" "Node resource usage" $KUBECTL top nodes

for n in "${NODES[@]}"; do
  run_capture "$OUTDIR/$n.describe.txt" "describe node $n" $KUBECTL describe node "$n"
  run_capture "$OUTDIR/$n.pods.txt" "Pods scheduled on $n" \
    $KUBECTL get pods --all-namespaces -o wide --field-selector "spec.nodeName=$n"
  run_capture "$OUTDIR/$n.conditions.txt" "Node conditions ($n)" \
    $KUBECTL get node "$n" -o jsonpath='{range .status.conditions[*]}{.type}={.status} ({.reason}){"\n"}{end}'
done
ok "Node info written to ./$OUTDIR/"
