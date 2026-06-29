---
title: Troubleshooting Decision Trees
type: reference
tags:
  - troubleshooting
  - decision-trees
  - mermaid
  - pods
  - services
  - nodes
  - storage
---

# Troubleshooting Decision Trees

These decision trees turn vague symptoms ("my app is down") into a concrete
next command and, ultimately, a specific error page. Start at the top of the
tree that matches your symptom, answer each question with `kubectl`, and follow
the branch. Every leaf links to the error page with the detailed fix.

> Tip: the three commands that drive almost every branch below are
> `kubectl get pods -o wide`, `kubectl describe pod <name>`, and
> `kubectl get events --sort-by=.lastTimestamp`.

## Pod not running

```mermaid
flowchart TD
    Start[Pod not running] --> Phase{kubectl get pod phase?}
    Phase -->|Pending| Sched{Events mention scheduling?}
    Sched -->|Insufficient cpu/memory| P1[See pending.md]
    Sched -->|Taints / nodeSelector / affinity| P1
    Sched -->|Unbound PVC| PVC[See PVC Pending tree]

    Phase -->|ContainerCreating| CC{Events?}
    CC -->|Failed to pull image| IPB[See imagepullbackoff.md]
    CC -->|Volume mount / attach error| VOL[See storage-failures]
    CC -->|Sandbox / CNI error| CNI[See networking-failures]

    Phase -->|Running but not Ready| RDY{Probe failing?}
    RDY -->|Readiness probe fails| PROBE[Check probe config and app health]

    Phase -->|CrashLoopBackOff| Logs{kubectl logs --previous}
    Logs -->|Exit non-zero / stack trace| CLB[See crashloopbackoff.md]
    Logs -->|OOMKilled in describe| OOM[See oomkilled.md]
    Logs -->|Bad command / config| CLB
```

**How to read it.** A Pod that never leaves `Pending` is the scheduler's
domain — it found no node, usually for resources, taints, or an unbound volume.
`ContainerCreating` means a node was chosen but the kubelet cannot bring the
container up: image, volume, or network. `CrashLoopBackOff` means the container
started and then exited repeatedly; the logs (especially `--previous`) and the
`Last State` in `kubectl describe` tell you whether it was an OOM kill, a bad
command, or an application error.

Leaf links: [`pending.md`](../errors/pods/pending.md),
[`imagepullbackoff.md`](../errors/pods/imagepullbackoff.md),
[`crashloopbackoff.md`](../errors/pods/crashloopbackoff.md),
[`oomkilled.md`](../errors/pods/oomkilled.md).

## Service unreachable

```mermaid
flowchart TD
    Start[Service unreachable] --> EP{kubectl get endpoints has addresses?}
    EP -->|No endpoints| Sel{Selector matches Pod labels?}
    Sel -->|No| FIX1[Fix Service selector. See networking-failures.md]
    Sel -->|Yes but Pods not Ready| FIX2[Fix readiness. See pods/pending.md]

    EP -->|Endpoints present| DNS{DNS resolves service name?}
    DNS -->|No| DNSFAIL[See dns-failures.md]
    DNS -->|Yes| PORT{Correct port and targetPort?}
    PORT -->|Mismatch| FIX3[Fix port mapping. See networking-failures.md]
    PORT -->|Correct| POL{NetworkPolicy blocking?}
    POL -->|Yes| FIX4[Adjust policy. See networking-failures.md]
    POL -->|No| KP{kube-proxy healthy on nodes?}
    KP -->|No| FIX5[Restart/repair kube-proxy. See networking-failures.md]
    KP -->|Ingress involved| ING[See ingress-failures.md]
```

**How to read it.** Work from the inside out. First confirm the Service has
endpoints — no endpoints almost always means the **selector** does not match
the Pods, or the Pods are not `Ready`. If endpoints exist, the problem is in
the path: DNS resolution, port/targetPort mapping, NetworkPolicy, or the
kube-proxy data plane. If an Ingress fronts the Service, jump to the ingress
page once the Service itself is proven healthy.

Leaf links: [`networking-failures.md`](../playbooks/networking-failures.md),
[`dns-failures.md`](../playbooks/dns-failures.md),
[`ingress-failures.md`](../playbooks/ingress-failures.md).

## Node NotReady

```mermaid
flowchart TD
    Start[Node NotReady] --> Desc{kubectl describe node conditions}
    Desc -->|kubelet not posting status| KUBELET{systemctl status kubelet}
    KUBELET -->|Stopped / crashing| FIX1[Restart kubelet, check logs. See node-failures.md]
    KUBELET -->|Cert expired| CERT[See certificate-expiration.md]

    Desc -->|MemoryPressure / DiskPressure| RES{Resource exhausted?}
    RES -->|Disk full| FIX2[Free disk / image gc. See node-failures.md]
    RES -->|Memory| FIX3[Evict / add capacity. See node-failures.md]

    Desc -->|NetworkUnavailable| NET[CNI not ready. See networking-failures.md]
    Desc -->|Runtime down| RT{container runtime healthy?}
    RT -->|No| FIX4[Restart containerd/CRI-O. See node-failures.md]
    Desc -->|Unreachable from control plane| CONN[Check network / firewall. See worker-node-unavailable]
```

**How to read it.** `NotReady` is a kubelet status, so start by asking why the
kubelet stopped reporting healthy: the kubelet process itself, an expired
client certificate, resource pressure (disk or memory), a missing CNI, or a
dead container runtime. `kubectl describe node` lists the conditions that point
to the right branch.

Leaf links: [`node-failures.md`](../playbooks/node-failures.md),
[`certificate-expiration.md`](../playbooks/certificate-expiration.md),
[`networking-failures.md`](../playbooks/networking-failures.md).

## PVC Pending

```mermaid
flowchart TD
    Start[PVC Pending] --> SC{StorageClass specified or default exists?}
    SC -->|No default, none set| FIX1[Set storageClassName or default SC. See persistent-volume-failures.md]
    SC -->|Yes| MODE{Provisioning mode?}
    MODE -->|Dynamic| PROV{Provisioner / CSI pod running?}
    PROV -->|No| FIX2[Fix CSI driver. See storage-failures.md]
    PROV -->|Yes but errors| QUOTA{Backend capacity / quota?}
    QUOTA -->|Exhausted| FIX3[Free capacity / raise quota. See storage-failures.md]

    MODE -->|Static| MATCH{Matching PV available?}
    MATCH -->|No PV matches size/accessMode| FIX4[Create matching PV. See persistent-volume-failures.md]
    MATCH -->|PV exists but wrong zone| ZONE[Fix topology/zone. See persistent-volume-failures.md]
```

**How to read it.** A `Pending` PVC means no PV is bound to it. For **dynamic**
provisioning, the StorageClass and its CSI provisioner must be healthy and the
backend must have capacity. For **static** provisioning, a pre-created PV must
match the claim's size, access mode, and topology. `kubectl describe pvc` shows
the provisioner's events and the exact reason.

Leaf links: [`persistent-volume-failures.md`](../playbooks/persistent-volume-failures.md),
[`storage-failures.md`](../playbooks/storage-failures.md).

## Putting it together

The four trees above cover the overwhelming majority of cluster incidents. The
shared discipline is: **read status, read events, follow the handoff that
failed.** When a leaf points to an error page, that page contains the exact
commands, root-cause explanation, and remediation steps. When two trees overlap
(for example a `Pending` Pod caused by a `Pending` PVC) follow the cross-link
rather than guessing — the storage tree will get you to the real root cause.
