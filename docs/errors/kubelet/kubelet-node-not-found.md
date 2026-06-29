---
title: "Kubelet Node Not Found"
error_message: "nodes \"node-1\" not found"
category: kubelet
severity: Critical
recovery_time: "10–40 min"
k8s_versions: "1.20+"
tags: [kubelet, registration, node-object, identity, notready]
related: ["Kubelet Cannot Connect To API Server", "Kubelet Client Certificate Expired", "Kubelet Failed To Start"]
---

# Kubelet Node Not Found

> **Severity:** Critical · **Typical recovery time:** 10–40 min · **Affected versions:** 1.20+

## Error Message

```text
kubelet: "Unable to register node with API server" err="nodes \"node-1\" not found"
kubelet: Error updating node status, will retry: error getting node "node-1": nodes "node-1" not found
```

## Description

The kubelet identifies itself by a node name (default the hostname) and expects
a matching Node object in the API. When it cannot find or create that object it
logs `nodes "<name>" not found` and cannot post status, so the node never
becomes `Ready` (or drops to `NotReady`). Pods do not schedule there, and any
running pods are eventually evicted.

This usually means an identity or lifecycle mismatch: the Node object was
deleted while the kubelet is still running, the kubelet's `--hostname-override`
no longer matches the registered name, or (in cloud setups) the cloud provider
removed the node from the API because the instance was considered gone.

## Affected Kubernetes Versions

Applies to 1.20+. With `--register-node=true` (default) the kubelet recreates
its Node object; if registration is disabled or RBAC forbids it, the object
stays missing. Cloud-controller-manager node lifecycle can also delete the
object out from under the kubelet.

## Likely Root Causes

- Node object manually deleted while the kubelet keeps running
- `--hostname-override` / node name mismatch between kubelet and registered Node
- `--register-node=false` or RBAC blocking the kubelet from creating the Node
- Cloud controller deleted the Node (instance seen as terminated)

## Diagnostic Flow

```mermaid
flowchart TD
    A[kubelet: nodes "X" not found] --> B{Node object exists?}
    B -- No --> C{register-node enabled?}
    C -- No --> D[Enable registration / RBAC]
    C -- Yes --> E[Check cloud controller deletion]
    B -- Yes --> F{Name matches kubelet?}
    F -- No --> G[Fix hostname-override]
```

## Verification Steps

Check whether a Node object with the kubelet's exact name exists, and compare it
to the kubelet's configured node name.

## kubectl Commands

```bash
kubectl get nodes
kubectl get node node-1 -o wide
kubectl get events -A --field-selector reason=RegisteredNode

# On the node host (read-only):
sudo journalctl -u kubelet --no-pager | grep -i 'not found\|register node'
sudo systemctl status kubelet
hostname
grep -i hostname /var/lib/kubelet/kubeadm-flags.env 2>/dev/null
```

## Expected Output

```text
$ kubectl get nodes
NAME     STATUS   ROLES    AGE   VERSION
node-2   Ready    <none>   30d   v1.29.4
# node-1 absent

$ sudo journalctl -u kubelet | grep 'not found'
"Unable to register node with API server" err="nodes \"node-1\" not found"
```

## Common Fixes

1. Let the kubelet re-register: ensure `--register-node=true` and the node has
   RBAC to create its Node object, then the object reappears.
2. Fix the name mismatch — set `--hostname-override` (or fix hostname) so it
   matches the registered Node name.
3. In cloud clusters, confirm the instance is healthy so the cloud controller
   stops deleting the Node; rejoin if it was decommissioned.

## Recovery Procedures

1. Determine whether the Node object is missing or merely name-mismatched.
2. For a name mismatch, correct the kubelet node name and **restart the
   kubelet** — blast radius: node-local control loop; pods keep running.
3. For a deleted Node object with registration enabled, **restart the kubelet**
   so it re-registers — blast radius: node-local; pods keep running.
4. If the node was genuinely decommissioned, **rejoin** it cleanly — blast
   radius: its pods reschedule; verify capacity first.

## Validation

`kubectl get node <name>` returns the object as `Ready`, status updates resume,
and the `not found` errors stop in the kubelet log.

## Prevention

Never delete Node objects of live nodes, keep `--hostname-override` stable and
consistent, ensure node RBAC permits registration, and alert when a known node
disappears from `kubectl get nodes`.

## Related Errors

- [Kubelet Cannot Connect To API Server](kubelet-cannot-connect-apiserver.md)
- [Kubelet Client Certificate Expired](kubelet-client-certificate-expired.md)
- [Kubelet Failed To Start](kubelet-failed-to-start.md)

## References

- [Nodes — registration](https://kubernetes.io/docs/concepts/architecture/nodes/#self-registration-of-nodes)
- [kubelet command reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)

## Further Reading

- [DevOps AI ToolKit — Kubernetes guides](https://devopsaitoolkit.com/blog/)
