# Diagnostic scripts (read-only)

These scripts collect a snapshot of cluster state to help you triage an
incident. **They are strictly read-only.**

> 🔒 **Safety contract:** every script here runs only non-mutating `kubectl`
> verbs (`get`, `describe`, `logs`, `top`, `version`, `api-resources`). None of
> them create, patch, delete, drain, cordon, uncordon, scale, apply, or taint
> anything. The shared helper (`lib-common.sh`) actively refuses to run a
> mutating verb.

## Requirements

- `kubectl` configured for the target cluster (set `KUBECTL=/path/to/kubectl`
  to override the binary)
- `bash` 4+
- Optional: `metrics-server` for `kubectl top` output

## Scripts

| Script | Purpose |
|--------|---------|
| `collect-cluster-diagnostics.sh` | Broad cluster snapshot: versions, nodes, events, component health, resource usage |
| `export-events.sh` | Export sorted events (optionally warnings-only) |
| `gather-pod-logs.sh` | Logs (incl. `--previous`) + `describe` for pods in a namespace |
| `gather-node-info.sh` | Node conditions, capacity, taints, and scheduled pods |
| `collect-ingress-info.sh` | Ingress, Services, Endpoints, and controller logs |
| `storage-diagnostics.sh` | StorageClasses, PVs, PVCs, VolumeAttachments, CSI drivers |
| `namespace-diagnostics.sh` | Everything in one namespace: workloads, events, quotas, policies |

## Examples

```bash
# Broad snapshot into a timestamped directory
./scripts/collect-cluster-diagnostics.sh

# Focus on one namespace
./scripts/namespace-diagnostics.sh -n payments

# Pod logs (including crashed containers' previous logs)
./scripts/gather-pod-logs.sh -n payments -l app=checkout

# Only warning events, written to a file
./scripts/export-events.sh --warnings-only -o warnings.txt
```

## A note on sensitive data

Output may contain pod names, node names, IPs, and config. The scripts never
print Secret *values* (only names), but **review any bundle before sharing it
outside your organization.**
