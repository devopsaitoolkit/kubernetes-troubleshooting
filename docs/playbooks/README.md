---
title: Troubleshooting Playbooks
type: index
tags:
  - playbooks
  - runbooks
  - troubleshooting
  - index
---

# Troubleshooting Playbooks

This directory contains 20 step-by-step playbooks for diagnosing and resolving
the most common Kubernetes failures. Each playbook is a self-contained runbook:
symptoms, how to confirm, root-cause analysis, and remediation. They are
grouped below by the part of the system that fails.

For visual decision support, pair these with the
[diagrams collection](../diagrams/README.md) — especially the
[decision trees](../diagrams/troubleshooting-decision-trees.md) and the
[incident flowcharts](../diagrams/incident-flowcharts.md).

## Workloads

- [Pods won't start](./pods-wont-start.md)
- [Image pull failures](./image-pull-failures.md)
- [Scheduling failures](./scheduling-failures.md)
- [Helm release failures](./helm-release-failures.md)
- [Autoscaler failures](./autoscaler-failures.md)

## Nodes

- [Node failures](./node-failures.md)
- [Worker node unavailable](./worker-node-unavailable.md)

## Control plane

- [Control plane failures](./control-plane-failures.md)
- [API server unavailable](./api-server-unavailable.md)
- [etcd unavailable](./etcd-unavailable.md)

## Storage

- [Storage failures](./storage-failures.md)
- [Persistent volume failures](./persistent-volume-failures.md)

## Networking

- [Networking failures](./networking-failures.md)
- [DNS failures](./dns-failures.md)
- [Ingress failures](./ingress-failures.md)

## Security / TLS

- [RBAC problems](./rbac-problems.md)
- [TLS certificate problems](./tls-certificate-problems.md)
- [Certificate expiration](./certificate-expiration.md)

## Lifecycle

- [Cluster upgrade failures](./cluster-upgrade-failures.md)
- [Cluster bootstrap failures](./cluster-bootstrap-failures.md)

## How to use a playbook

1. Match your symptom to a group above and open the playbook.
2. Run the **confirm** commands to verify you're in the right place.
3. Follow the **diagnose** steps to find the root cause.
4. Apply the **remediate** steps, then validate recovery.

If a playbook doesn't resolve the issue, escalate using the
[escalation tree](../diagrams/incident-flowcharts.md) and capture what was
missing in the postmortem so it can be added here.
