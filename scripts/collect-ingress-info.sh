#!/usr/bin/env bash
# collect-ingress-info.sh — snapshot Ingress, IngressClass, Services, and
# Endpoints, plus the ingress-controller pod logs (READ-ONLY). Useful for
# 502/503/404 and "default backend" investigations.
#
# Usage: ./collect-ingress-info.sh [-n app-namespace] [-c controller-namespace] [-o dir]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "$SCRIPT_DIR/lib-common.sh"

NS=""; CTRL_NS="ingress-nginx"; OUTDIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n) NS="$2"; shift 2 ;;
    -c) CTRL_NS="$2"; shift 2 ;;
    -o) OUTDIR="$2"; shift 2 ;;
    -h) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) err "Unknown arg: $1"; exit 1 ;;
  esac
done

require_kubectl; check_context
OUTDIR="${OUTDIR:-ingress-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"
SCOPE=(--all-namespaces); [ -n "$NS" ] && SCOPE=(-n "$NS")

run_capture "$OUTDIR/ingressclasses.txt" "IngressClasses" $KUBECTL get ingressclass -o wide
run_capture "$OUTDIR/ingresses.txt"      "Ingresses"      $KUBECTL get ingress "${SCOPE[@]}" -o wide
run_capture "$OUTDIR/ingresses-describe.txt" "Ingress details" $KUBECTL describe ingress "${SCOPE[@]}"
run_capture "$OUTDIR/services.txt"       "Services"       $KUBECTL get svc "${SCOPE[@]}" -o wide
run_capture "$OUTDIR/endpoints.txt"      "Endpoints (are backends ready?)" \
  $KUBECTL get endpoints "${SCOPE[@]}"
run_capture "$OUTDIR/endpointslices.txt" "EndpointSlices" \
  $KUBECTL get endpointslices "${SCOPE[@]}" -o wide

if $KUBECTL get ns "$CTRL_NS" >/dev/null 2>&1; then
  run_capture "$OUTDIR/controller-pods.txt" "Ingress controller pods ($CTRL_NS)" \
    $KUBECTL get pods -n "$CTRL_NS" -o wide
  for p in $($KUBECTL get pods -n "$CTRL_NS" -o name 2>/dev/null); do
    name="${p#pod/}"
    run_capture "$OUTDIR/controller-$name.log.txt" "Controller log: $name" \
      $KUBECTL logs "$p" -n "$CTRL_NS" --tail=1000
  done
else
  warn "Controller namespace '$CTRL_NS' not found; pass -c <namespace>."
fi
ok "Ingress info written to ./$OUTDIR/"
