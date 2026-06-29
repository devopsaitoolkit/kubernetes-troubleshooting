---
title: "Failed To Stop Container"
error_message: "failed to stop container ...: failed to kill task: context deadline exceeded"
category: container-runtime
severity: High
recovery_time: "10–45 min"
k8s_versions: "1.20+"
tags: [containerd, shim, terminating, sigkill, timeout]
related: ["Pod Stuck Terminating", "Failed To Create containerd Task", "containerd Connection Refused"]
---

# Failed To Stop Container

> **Severity:** High · **Typical recovery time:** 10–45 min · **Affected versions:** 1.20+

## Error Message

```text
failed to stop container "<id>": failed to kill task "<id>": context deadline
exceeded: unknown
```

```text
StopPodSandbox ... rpc error: code = DeadlineExceeded desc = failed to stop
container ...
```

## Description

When a pod is deleted, the kubelet asks the runtime to stop each container:
send the stop signal, wait the grace period, then `SIGKILL`. `failed to kill
task: context deadline exceeded` means even the kill did not complete in time —
the runtime/shim could not reap the process. The pod gets stuck `Terminating`
and its resources (IP, volumes, names) are not released, which can block
rollouts, scale-downs, and StatefulSet pod replacement.

This is a runtime/kernel issue: the process is unkillable (uninterruptible `D`
state on stuck I/O), the shim is wedged, or containerd is overloaded. It is the
teardown counterpart to "failed to create task."

## Affected Kubernetes Versions

All containerd/CRI-O clusters. containerd 1.6+ uses `containerd-shim-runc-v2`;
a hung shim is the usual culprit. The kubelet's stop timeout interacts with the
pod's `terminationGracePeriodSeconds`. Behaviour is otherwise version-stable.

## Likely Root Causes

- Process stuck in uninterruptible sleep (`D` state) on blocked I/O (NFS, stuck
  device) so even SIGKILL cannot reap it
- Wedged or dead `containerd-shim` for the container
- containerd daemon overloaded/unresponsive (high load, OOM)
- Defunct/zombie processes the shim cannot reap
- Kernel/cgroup freezer issues preventing the task from being killed

## Diagnostic Flow

```mermaid
flowchart TD
    A[Pod stuck Terminating] --> B{Event: failed to kill task deadline?}
    B -- No --> B2[Check finalizers / volume detach]
    B -- Yes --> C{Process in D state?}
    C -- Yes --> D[Trace blocked I/O (NFS/device)]
    C -- No --> E{Shim process alive/responsive?}
    E -- No --> F[Stuck shim - clean up runtime state]
    E -- Yes --> G[Check containerd load / health]
```

## Verification Steps

Confirm the event names `failed to kill task` / `context deadline exceeded` and
that the pod is `Terminating`. Determine on the node whether the process is in
`D` state and whether its shim is alive.

## kubectl Commands

```bash
kubectl describe pod <pod> -n <namespace>
kubectl get pod <pod> -n <namespace> -o jsonpath='{.metadata.deletionTimestamp} {.metadata.finalizers}'
kubectl get events -n <namespace> --sort-by=.lastTimestamp
# On the affected node (read-only):
crictl ps -a
crictl inspect <container-id>
journalctl -u containerd --since "20 min ago" --no-pager | grep -i "kill task"
systemctl status containerd
```

## Expected Output

```text
  Warning  FailedKillPod  9s  kubelet  error killing pod: failed to "KillContainer"
  for "app" with KillContainerError: "rpc error: code = DeadlineExceeded
  desc = failed to stop container "<id>": failed to kill task "<id>":
  context deadline exceeded: unknown"
```

## Common Fixes

1. Clear the blocked I/O: recover the stuck backend (NFS server/mount, failing
   disk); once I/O unblocks, the `D`-state process exits and the kill completes.
2. Increase `terminationGracePeriodSeconds` only for workloads that legitimately
   need longer to drain — it does not fix a truly hung process.
3. Repair an overloaded/unresponsive containerd (relieve memory/CPU pressure).

## Recovery Procedures

1. Resolve the underlying I/O/shim cause; the container then stops and the pod
   leaves `Terminating` — lowest blast radius.
2. If a single shim is wedged, cleaning that container's runtime state via node
   tooling affects only that pod; verify before acting.
3. If containerd itself is hung, restarting it is **node-wide blast radius**
   (all containers recreated) — drain first. A `D`-state process surviving a
   daemon restart usually requires a **node reboot — all pods reschedule.**

## Validation

The pod disappears from `kubectl get pods` (no longer `Terminating`); `crictl
ps -a` no longer lists the container; its IP/volumes are released and
replacements schedule.

## Prevention

- Use reliable storage; avoid hard NFS mounts that can wedge processes.
- Set realistic `terminationGracePeriodSeconds` and graceful `preStop` handling.
- Monitor `D`-state process counts, shim health, and containerd resource usage.

## Related Errors

- [Pod Stuck Terminating](../pods/pod-stuck-terminating.md)
- [Failed To Create containerd Task](failed-to-create-containerd-task.md)
- [containerd Connection Refused](containerd-connection-refused.md)
- [Node kernel hung](../nodes/node-kernel-hung.md)

## References

- [Kubernetes: Pod lifecycle (termination)](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)
- [containerd CRI configuration](https://github.com/containerd/containerd/blob/main/docs/cri/config.md)

## Further Reading

- [DevOps AI ToolKit — Kubernetes guides](https://devopsaitoolkit.com/blog/)
