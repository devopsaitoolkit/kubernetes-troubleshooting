# Error library

300+ Kubernetes production errors, one page each, organized by subsystem. Use
the offline search tool to find an error fast:

```bash
python tools/search.py CrashLoopBackOff
python tools/search.py --category storage --severity Critical
```

## Subsystems

| Directory | Covers |
|-----------|--------|
| [`pods/`](./pods/) | Pod lifecycle: CrashLoopBackOff, ImagePullBackOff, OOMKilled, Pending, container config |
| [`deployments/`](./deployments/) | Rollouts, replicas, progress deadlines |
| [`daemonsets/`](./daemonsets/) | Per-node scheduling and rollout issues |
| [`statefulsets/`](./statefulsets/) | Ordered pods, stable identity, volume templates |
| [`jobs/`](./jobs/) | Batch jobs, backoff limits, completions |
| [`cronjobs/`](./cronjobs/) | Schedules, concurrency, missed runs |
| [`nodes/`](./nodes/) | NodeNotReady, pressure conditions, evictions |
| [`networking/`](./networking/) | CNI, pod-to-pod, DNS, NetworkPolicy, kube-proxy |
| [`ingress/`](./ingress/) | Ingress controllers, 502/503/404, TLS |
| [`services/`](./services/) | ClusterIP/NodePort/LoadBalancer, endpoints |
| [`storage/`](./storage/) | CSI, mounts, attach/detach |
| [`persistent-volumes/`](./persistent-volumes/) | PV lifecycle, reclaim, binding |
| [`persistent-volume-claims/`](./persistent-volume-claims/) | PVC provisioning and binding |
| [`rbac/`](./rbac/) | Forbidden, roles, bindings, service accounts |
| [`security/`](./security/) | Pod Security, secrets, TLS, certificates |
| [`helm/`](./helm/) | Releases, upgrades, hooks, rollbacks |
| [`cert-manager/`](./cert-manager/) | Certificates, issuers, ACME challenges |
| [`monitoring/`](./monitoring/) | metrics-server, Prometheus, scraping |
| [`autoscaling/`](./autoscaling/) | HPA, VPA, cluster-autoscaler |
| [`api-server/`](./api-server/) | Availability, throttling, timeouts, webhooks |
| [`etcd/`](./etcd/) | Quorum, space, latency, compaction |
| [`scheduler/`](./scheduler/) | FailedScheduling, affinity, taints, topology |
| [`controller-manager/`](./controller-manager/) | Controllers, leader election |
| [`admission/`](./admission/) | Validating/mutating webhooks, policy denials |
| [`kubelet/`](./kubelet/) | Node agent, PLEG, image GC, cgroups |
| [`container-runtime/`](./container-runtime/) | containerd/CRI-O, image pulls, sandbox |

## Page format

See [`_TEMPLATE.md`](./_TEMPLATE.md). Every page targets one error and one
primary search phrase, with a full diagnostic flow, read-only `kubectl`
commands, fixes, recovery, validation, and prevention.

> Spotted a gap? [Request a new error page](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/issues/new?template=new_error_request.yml)
> or open a PR — see [CONTRIBUTING](../../CONTRIBUTING.md).
