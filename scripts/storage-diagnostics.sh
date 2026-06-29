#!/usr/bin/env bash
# storage-diagnostics.sh — snapshot StorageClasses, PVs, PVCs, VolumeAttachments,
# and CSI drivers (READ-ONLY). Useful for Pending PVCs, FailedMount, and
# FailedAttachVolume investigations.
#
# Usage: ./storage-diagnostics.sh [-n namespace] [-o dir]
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

require_kubectl; check_context
OUTDIR="${OUTDIR:-storage-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"
SCOPE=(--all-namespaces); [ -n "$NS" ] && SCOPE=(-n "$NS")

run_capture "$OUTDIR/storageclasses.txt"     "StorageClasses (note the default)" \
  $KUBECTL get storageclass -o wide
run_capture "$OUTDIR/pv.txt"                 "PersistentVolumes" $KUBECTL get pv -o wide
run_capture "$OUTDIR/pv-describe.txt"        "PV details"        $KUBECTL describe pv
run_capture "$OUTDIR/pvc.txt"                "PersistentVolumeClaims" \
  $KUBECTL get pvc "${SCOPE[@]}" -o wide
run_capture "$OUTDIR/pvc-describe.txt"       "PVC details (look for ProvisioningFailed)" \
  $KUBECTL describe pvc "${SCOPE[@]}"
run_capture "$OUTDIR/volumeattachments.txt"  "VolumeAttachments" \
  $KUBECTL get volumeattachment -o wide
run_capture "$OUTDIR/csidrivers.txt"         "CSI drivers"       $KUBECTL get csidrivers -o wide
run_capture "$OUTDIR/csinodes.txt"           "CSI nodes"         $KUBECTL get csinodes -o wide
run_capture "$OUTDIR/storage-events.txt"     "Storage-related events" \
  bash -c "$KUBECTL get events ${SCOPE[*]} --sort-by=.lastTimestamp | grep -Ei 'volume|mount|attach|provision|pvc|pv ' || true"
ok "Storage diagnostics written to ./$OUTDIR/"
