#!/usr/bin/env bash
# Shared helpers for the diagnostic scripts in this directory.
#
# SAFETY CONTRACT: every script that sources this file is READ-ONLY. It runs
# only `get`, `describe`, `logs`, `top`, `version`, `api-resources` and similar
# non-mutating kubectl verbs. Nothing here ever creates, patches, deletes,
# drains, cordons, evicts, scales, or applies anything to your cluster.

set -euo pipefail

KUBECTL="${KUBECTL:-kubectl}"
NS_FLAG=""
OUTDIR_DEFAULT="diagnostics-$(date +%Y%m%d-%H%M%S)"

color() { # color <code> <text>
  if [ -t 1 ]; then printf '\033[%sm%s\033[0m' "$1" "$2"; else printf '%s' "$2"; fi
}
info()  { echo "$(color '0;36' '[*]') $*"; }
ok()    { echo "$(color '0;32' '[ok]') $*"; }
warn()  { echo "$(color '0;33' '[!]') $*" >&2; }
err()   { echo "$(color '0;31' '[x]') $*" >&2; }

require_kubectl() {
  if ! command -v "$KUBECTL" >/dev/null 2>&1; then
    err "kubectl not found on PATH (set KUBECTL=/path/to/kubectl to override)."
    exit 1
  fi
  if ! "$KUBECTL" version --client >/dev/null 2>&1; then
    err "kubectl client is not working; check your installation."
    exit 1
  fi
}

check_context() {
  local ctx
  ctx="$($KUBECTL config current-context 2>/dev/null || echo 'unknown')"
  info "Using kube-context: $(color '1;37' "$ctx")"
  info "This script is READ-ONLY and will not modify the cluster."
}

# run_capture <outfile> <description> <cmd...>
# Runs a read-only command, prints a header, captures stdout+stderr to a file.
run_capture() {
  local outfile="$1"; shift
  local desc="$1"; shift
  info "Collecting: $desc"
  {
    echo "# $desc"
    echo "# \$ $*"
    echo "# $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    "$@" 2>&1 || echo "(command returned non-zero; output captured above)"
  } > "$outfile"
}

# Reject any obviously mutating verb if a caller tries to pass one.
assert_readonly() {
  case " $* " in
    *" delete "*|*" apply "*|*" patch "*|*" edit "*|*" drain "*|*" cordon "*|\
*" uncordon "*|*" scale "*|*" create "*|*" replace "*|*" rollout restart "*|*" taint "*)
      err "Refusing to run a mutating kubectl verb: $*"
      exit 2
      ;;
  esac
}
