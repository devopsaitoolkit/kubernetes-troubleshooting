---
title: "kubectl Troubleshooting Command Reference"
type: reference
tags: [kubectl, reference, commands]
---

# kubectl Troubleshooting Command Reference

When something breaks in a Kubernetes cluster, `kubectl` is your primary diagnostic instrument. This reference collects the commands that matter most during an incident, organized by command group. Each entry explains **when to use** it, shows a copy-pasteable `bash` example, the **expected output** you should look for, and the **common mistakes** that waste time or cause damage.

The goal is to help you move from symptom to root cause quickly without making the situation worse. Most troubleshooting is observation, not mutation. Treat the cluster like a crime scene: look before you touch.

## Read-only first

The overwhelming majority of troubleshooting should be **read-only**. Commands like `describe`, `logs`, `get`, `events`, `top`, `auth can-i`, `api-resources`, and `explain` never change cluster state and are always safe to run. Prefer them.

A small number of commands **change state and have a blast radius**: `drain`, `cordon`/`uncordon`, `rollout undo`, `rollout restart`, and `cp` *into* a running container. These are flagged explicitly below. Before running any of them, confirm your `kubectl config current-context` points at the cluster you think it does, and understand who and what the command affects. When in doubt, run with `--dry-run=server` first.

A quick context sanity check before anything else:

```bash
kubectl config current-context
kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'
```

## describe (read-only)

**When to use:** Your first stop for any unhealthy object. `describe` aggregates spec, status, conditions, and the recent Events for a single resource into one human-readable view. It answers "why is this Pod not running?" faster than anything else.

```bash
kubectl describe pod web-7f9c-abc12 -n production
```

**Expected output:**

```text
Name:         web-7f9c-abc12
Namespace:    production
Status:       Pending
Containers:
  web:
    State:          Waiting
      Reason:       ImagePullBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
Events:
  Type     Reason     Age   From     Message
  ----     ------     ----  ----     -------
  Warning  Failed     2m    kubelet  Failed to pull image "web:v9": not found
```

**Common mistakes:** Forgetting `-n <namespace>` and getting "NotFound" for a Pod that exists elsewhere. Ignoring the `Last State` / `Exit Code` block, which often holds the real cause (137 = OOM/SIGKILL, 1 = app error). Reading only the spec and skipping the Events at the bottom, which is where kubelet and scheduler messages land.

## logs (read-only)

**When to use:** To read what the application itself printed. Essential for crash loops, errors, and confirming startup behavior.

```bash
# Current logs, follow live, last 15 minutes, specific container
kubectl logs deploy/web -n production --since=15m -f -c web
# Logs from the PREVIOUS, crashed container instance
kubectl logs web-7f9c-abc12 -n production --previous
```

Key flags: `--previous` (`-p`) reads the prior crashed container — critical for CrashLoopBackOff. `-f` streams live. `--since=15m` or `--since-time` bounds the window. `-c <name>` selects one container in a multi-container Pod; `--all-containers=true` shows all. `--tail=100` limits volume.

**Expected output:**

```text
2026-06-24T10:15:02Z INFO  starting server on :8080
2026-06-24T10:15:03Z FATAL config: DATABASE_URL is empty
```

**Common mistakes:** Forgetting `--previous` on a crash loop and seeing only the brand-new container's sparse logs. Omitting `-c` on a multi-container Pod and getting an error or the wrong container. Tailing huge logs without `--tail`/`--since` and flooding your terminal. Note that logs are gone once a Pod is deleted — capture them first.

## get (read-only)

**When to use:** Fast, scriptable listing and field extraction across resources. The output formatters make it the Swiss Army knife of inspection.

```bash
kubectl get pods -n production -o wide --sort-by=.status.startTime
kubectl get pod web-7f9c-abc12 -n production -o yaml
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
kubectl get pods -A --field-selector=status.phase=Running
```

`-o wide` adds node and IP columns. `-o yaml` dumps the full object including status. `-o jsonpath` extracts specific fields. `--field-selector` filters server-side (limited fields). `--sort-by` orders by any JSONPath.

**Expected output:**

```text
NAME              READY   STATUS             RESTARTS   AGE   IP           NODE
web-7f9c-abc12    0/1     CrashLoopBackOff   5          6m    10.1.2.3     node-2
```

**Common mistakes:** Expecting `--field-selector` to support arbitrary fields — only a few (e.g. `status.phase`, `metadata.name`, `spec.nodeName`) are indexed. Confusing `-A`/`--all-namespaces` with `-n`. Forgetting that `-o yaml` shows `status`, which is where conditions and timestamps live.

## events (read-only)

**When to use:** To see the cluster's chronological narrative — scheduling decisions, image pulls, probe failures, evictions. Events expire (default ~1h), so check them early.

```bash
kubectl get events -n production --sort-by=.lastTimestamp
kubectl get events -n production -w   # watch live
kubectl events --for pod/web-7f9c-abc12 -n production   # newer subcommand
```

**Expected output:**

```text
LAST SEEN   TYPE      REASON      OBJECT             MESSAGE
3m          Warning   BackOff     pod/web-7f9c       Back-off restarting failed container
2m          Warning   Unhealthy   pod/web-7f9c       Liveness probe failed: HTTP 500
```

**Common mistakes:** Not sorting — default order is not chronological, making timelines confusing. Always use `--sort-by=.lastTimestamp` (or `.metadata.creationTimestamp`). Forgetting events are namespaced and short-lived; if you wait too long they vanish.

## top (read-only)

**When to use:** To see live CPU/memory consumption for capacity and OOM investigations. Requires the metrics-server.

```bash
kubectl top nodes
kubectl top pods -n production --containers --sort-by=memory
```

**Expected output:**

```text
NAME       CPU(cores)   MEMORY(bytes)
web-7f9c   480m         1900Mi
```

**Common mistakes:** Running `top` without metrics-server installed (you'll get "Metrics API not available"). Confusing `top` (live usage) with `describe`'s requests/limits (configured values) — an OOMKill happens when usage exceeds the *limit*, which `top` alone won't show.

## exec (read-only diagnostics only)

**When to use:** To run read-only diagnostic commands *inside* a running container — checking env vars, config files, DNS, or reachability from the Pod's network identity.

```bash
kubectl exec -it web-7f9c-abc12 -n production -c web -- sh -c 'env | sort; cat /etc/resolv.conf'
```

**Expected output:**

```text
DATABASE_URL=
PORT=8080
nameserver 10.96.0.10
```

**Common mistakes:** Using `exec` to *fix* things by hand — editing files or restarting processes inside a container creates undocumented drift that vanishes on the next restart. Keep `exec` to inspection. Forgetting `-c` on multi-container Pods. Assuming a shell exists — distroless images may have no `sh`; use `debug` instead.

## cp (state-changing into container — blast radius: one container)

**When to use:** Mostly to copy a file *out* of a Pod for offline analysis (read-only direction). Copying *into* a container mutates that container's filesystem and is **state-changing** — flagged here because it introduces drift.

```bash
# Read-only direction: copy a heap dump OUT for analysis
kubectl cp production/web-7f9c-abc12:/tmp/heap.hprof ./heap.hprof -c web
```

**Expected output:**

```text
(no output on success; ./heap.hprof now exists locally)
```

**Common mistakes:** Copying *into* a live container as a "quick fix" — the change is lost on restart and is invisible to anyone reading the manifests. Requires `tar` in the container image; fails silently-ish without it.

## debug (read-only diagnostics; ephemeral container shares a running Pod)

**When to use:** To troubleshoot Pods that lack a shell (distroless) or to inspect a node, without modifying the workload. Ephemeral containers attach to a running Pod; node debug gives a privileged toolbox on a host.

```bash
# Attach a debug toolbox sharing the target container's process namespace
kubectl debug -it web-7f9c-abc12 -n production --image=busybox:1.36 --target=web -- sh
# Debug a node (mounts host fs at /host)
kubectl debug node/node-2 -it --image=busybox:1.36 -- sh
```

**Expected output:**

```text
Defaulting debug container name to debugger-x4q2.
/ #
```

**Common mistakes:** Forgetting `--target` so the debug container can't see the target process namespace. Treating node-debug as harmless — it runs privileged on the host; observe, don't modify. Ephemeral containers can't be removed individually (only by deleting the Pod), so don't leave them lingering.

## drain (STATE-CHANGING — blast radius: ALL pods on a node)

**When to use:** Before node maintenance, to safely evict all Pods so they reschedule elsewhere. This **disrupts every workload on the node**. High blast radius.

```bash
kubectl drain node-2 --ignore-daemonsets --delete-emptydir-data --dry-run=server
# remove --dry-run=server to actually drain
```

**Expected output:**

```text
node/node-2 cordoned (dry run)
evicting pod production/web-7f9c-abc12 (dry run)
```

**Common mistakes:** Forgetting `--ignore-daemonsets` (drain stalls). Forgetting `--delete-emptydir-data` and being blocked by Pods with emptyDir volumes. Not checking PodDisruptionBudgets first — a tight PDB can block or stall eviction. Draining without spare capacity, causing the evicted Pods to go Pending.

## cordon / uncordon (STATE-CHANGING — blast radius: scheduling on one node)

**When to use:** `cordon` marks a node unschedulable (existing Pods keep running) so new Pods avoid it while you investigate. `uncordon` reverses it. Lower blast radius than drain but still changes scheduling behavior.

```bash
kubectl cordon node-2
kubectl uncordon node-2
```

**Expected output:**

```text
node/node-2 cordoned
```

**Common mistakes:** Cordoning a node and forgetting to `uncordon` it, slowly shrinking cluster capacity. Expecting `cordon` to evict Pods — it does not; that's `drain`.

## rollout (status/history read-only; undo/restart STATE-CHANGING)

**When to use:** `status` and `history` are read-only progress/audit views. `undo` and `restart` change running workloads.

```bash
kubectl rollout status deploy/web -n production            # read-only
kubectl rollout history deploy/web -n production           # read-only
kubectl rollout undo deploy/web -n production --to-revision=3   # STATE-CHANGING
kubectl rollout restart deploy/web -n production               # STATE-CHANGING
```

`rollout undo` (**blast radius: all replicas of the Deployment**) reverts to a prior ReplicaSet. `rollout restart` (**blast radius: all replicas**) triggers a fresh rolling replacement of every Pod.

**Expected output:**

```text
deployment "web" successfully rolled out
```

**Common mistakes:** Running `undo` without checking `history` first and reverting to a revision that has the same bug. Using `restart` as a sledgehammer when the real fix is config; it churns every Pod and can mask the root cause.

## auth (read-only)

**When to use:** To answer "am I even allowed to do this?" before blaming the cluster. Great for diagnosing RBAC-related failures.

```bash
kubectl auth can-i delete pods -n production
kubectl auth can-i --list -n production
kubectl auth whoami
```

**Expected output:**

```text
yes
```

**Common mistakes:** Forgetting `-n`; permissions are often namespace-scoped. Forgetting you can impersonate to test another identity: `--as=system:serviceaccount:production:web`.

## api-resources / api-versions (read-only)

**When to use:** To discover what kinds exist (including CRDs), their short names, API groups, and whether they're namespaced.

```bash
kubectl api-resources --namespaced=true
kubectl api-versions
```

**Expected output:**

```text
NAME    SHORTNAMES   APIVERSION   NAMESPACED   KIND
pods    po           v1           true         Pod
```

**Common mistakes:** Guessing a resource name when `api-resources` would confirm it. Forgetting that `api-versions` reveals which API a CRD or built-in is served under (useful for deprecations).

## cluster-info (read-only)

**When to use:** To confirm the control plane and core add-ons are reachable, and to gather a support bundle.

```bash
kubectl cluster-info
kubectl cluster-info dump --output-directory=./cluster-dump   # read-only export
```

**Expected output:**

```text
Kubernetes control plane is running at https://10.0.0.1:6443
CoreDNS is running at https://10.0.0.1:6443/api/v1/.../coredns:dns/proxy
```

**Common mistakes:** Mistaking a reachable API server for a healthy cluster — `cluster-info` only proves connectivity, not node or workload health. Running `dump` against a huge cluster without a target directory.

## explain (read-only)

**When to use:** To learn the schema of any field without leaving the terminal — invaluable when writing or correcting manifests.

```bash
kubectl explain pod.spec.containers.resources --recursive
```

**Expected output:**

```text
KIND:     Pod
FIELD:    resources <ResourceRequirements>
DESCRIPTION:
   Compute Resources required by this container...
```

**Common mistakes:** Not using `--recursive` to see nested fields. Forgetting you can pin a version with `--api-version` when a field differs across releases.

## Further Reading

For more SRE playbooks, incident-response patterns, and AI-assisted DevOps tooling, see [devopsaitoolkit.com](https://devopsaitoolkit.com). Also keep the official `kubectl` reference and the Kubernetes "Debug Running Pods" task guide bookmarked.
