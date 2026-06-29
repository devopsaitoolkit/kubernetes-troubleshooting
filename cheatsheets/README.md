---
title: "Kubernetes Troubleshooting Cheatsheets"
type: index
tags: [kubectl, cheatsheet, index]
---

# Kubernetes Troubleshooting Cheatsheets

A small set of one-page, read-only-first references for diagnosing Kubernetes problems fast. State-changing commands are clearly flagged with their blast radius wherever they appear.

## Cheatsheets

- [Pod Troubleshooting](./pod-troubleshooting.md) — CrashLoopBackOff, ImagePullBackOff, Pending, and OOMKilled, with a decision tree.
- [Networking & DNS Troubleshooting](./networking-troubleshooting.md) — services, endpoints, CoreDNS, and NetworkPolicy, with a flow chart.
- [Cluster Health Triage](./cluster-health.md) — control plane, nodes, etcd, and core add-ons triage.

## Full reference

- [kubectl Troubleshooting Command Reference](../docs/reference/kubectl-troubleshooting.md) — every major diagnostic command group with when-to-use, examples, expected output, and common mistakes.

## How to use these

Start with the cluster-health cheatsheet if the whole cluster feels broken, the networking cheatsheet if a specific service is unreachable, and the pod cheatsheet if a specific workload is failing. Reach for the full command reference when you need the exact flags, output formats, and caveats for any single command.
