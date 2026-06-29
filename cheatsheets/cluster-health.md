---
title: "Cluster Health Triage Cheatsheet"
type: cheatsheet
tags: [kubectl, cluster, nodes, control-plane, etcd, cheatsheet]
---

# Cluster Health Triage Cheatsheet

Fast triage when "the whole cluster feels broken." Work top-down: control plane → nodes → core add-ons → workloads. All commands below are **read-only**.

## First 60 seconds

| Goal | Command |
|------|---------|
| Confirm you're on the right cluster | `kubectl config current-context` |
| API server reachable? | `kubectl cluster-info` |
| Node readiness overview | `kubectl get nodes -o wide` |
| Cluster-wide recent events | `kubectl get events -A --sort-by=.lastTimestamp` |
| Pods not Running anywhere | `kubectl get pods -A --field-selector=status.phase!=Running` |
| Node resource pressure | `kubectl top nodes` |

## Control plane

```bash
kubectl get componentstatuses              # legacy, may be deprecated
kubectl get pods -n kube-system -o wide     # static control-plane pods on kubeadm
kubectl get --raw='/readyz?verbose'         # API server self-check
kubectl get --raw='/livez?verbose'
```

Look for `apiserver`, `etcd`, `scheduler`, and `controller-manager` reporting healthy. On managed clusters (EKS/GKE/AKS) the control plane is hidden — use the provider console/status page; you'll still see symptoms via `events` and stuck workloads.

**Expected `/readyz` output:**

```text
[+]ping ok
[+]etcd ok
[+]poststarthook/start-kube-apiserver-admission-initializer ok
readyz check passed
```

## Nodes

```bash
kubectl get nodes
kubectl describe node <node>     # Conditions + Events + capacity
```

Key node **Conditions**: `Ready=True` is good. Watch for `MemoryPressure`, `DiskPressure`, `PIDPressure` = `True`, which trigger evictions. `NotReady` usually means a kubelet, container-runtime, or network/CNI problem on that node.

**Expected `describe node` Conditions block:**

```text
Conditions:
  Type             Status
  MemoryPressure   False
  DiskPressure     False
  PIDPressure      False
  Ready            True
```

Common causes of `NotReady`: kubelet down, CNI plugin not ready, disk full on `/var`, or the node lost connectivity to the API server. Check the node's Events and (if you have access) `journalctl -u kubelet` on the host.

## etcd

etcd is the cluster's source of truth; if it's unhealthy, everything is. On self-managed kubeadm clusters etcd runs as static Pods:

```bash
kubectl get pods -n kube-system -l component=etcd -o wide
kubectl logs -n kube-system etcd-<node> | tail -n 50
```

Watch for `apply request took too long`, `leader changed`, or `database space exceeded` (etcd quota, default 2 GiB → `NOSPACE` alarm and read-only API writes). Slow etcd disk I/O is the single most common cause of cluster-wide latency. On managed clusters etcd is invisible — escalate to the provider.

## Core add-ons

```bash
kubectl get pods -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns      # CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-proxy
```

If CoreDNS is unhealthy, *every* service-name lookup fails and the cluster looks broadly broken. If kube-proxy is down on a node, Service VIPs won't route there.

## Capacity & scheduling pressure

```bash
kubectl top nodes
kubectl get pods -A --field-selector=status.phase=Pending
kubectl describe node <node> | grep -A6 'Allocated resources'
```

A wave of `Pending` Pods with `FailedScheduling` events points to genuine capacity exhaustion or taints, not a software bug.

## Triage flow

1. **Right cluster?** `current-context` — avoid debugging the wrong place.
2. **API up?** `cluster-info` + `/readyz`. If down, it's control-plane/etcd; stop and escalate.
3. **Nodes Ready?** `get nodes`. NotReady → kubelet/CNI/disk on those nodes.
4. **Add-ons up?** CoreDNS, kube-proxy in `kube-system`.
5. **Events** `get events -A --sort-by=.lastTimestamp` for the global narrative.
6. **Capacity** `top nodes` + Pending pods.

## When you must change state

Node maintenance is **state-changing with high blast radius** — flagged, not part of read-only triage:

```bash
kubectl cordon <node>                                   # stop new scheduling
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data   # evict ALL pods
kubectl uncordon <node>                                 # re-enable when done
```

Always confirm spare capacity and PodDisruptionBudgets before draining, and remember to `uncordon` afterward.
