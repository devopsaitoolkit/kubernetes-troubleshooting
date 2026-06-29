---
title: Kubernetes Diagrams
type: reference
tags:
  - diagrams
  - mermaid
  - architecture
  - troubleshooting
  - networking
  - storage
  - incident-response
---

# Kubernetes Diagrams

A collection of Mermaid diagrams that visualize how Kubernetes works and how
to troubleshoot it when it doesn't. Every diagram in this directory renders
natively on GitHub (and most Markdown viewers that support Mermaid), so you can
read them directly in the browser without any build step.

These diagrams are meant to be skimmed during an incident and studied in calmer
moments. Pair them with the [error pages](../errors/) and the
[playbooks](../playbooks/) for the full troubleshooting flow.

## Diagrams in this collection

- **[Architecture](./architecture.md)** — Control plane and node components,
  and how an API request and a Pod scheduling request flow through the system.
- **[Troubleshooting decision trees](./troubleshooting-decision-trees.md)** —
  `flowchart TD` decision trees for the most common failure classes: *Pod not
  running*, *Service unreachable*, *Node NotReady*, and *PVC Pending*. Leaves
  link to the matching error page.
- **[Incident response flowcharts](./incident-flowcharts.md)** — The on-call
  triage workflow (detect → scope → diagnose → mitigate → validate →
  postmortem) and an escalation tree.
- **[Networking & storage](./networking-and-storage.md)** — Pod-to-pod and DNS
  resolution paths, the Service/Endpoints/kube-proxy data path, and the CSI
  provision/attach/mount and PV/PVC binding lifecycles.

## How to use these

1. **During an incident**, jump to the decision tree that matches the symptom,
   follow it to a leaf, and open the linked error page.
2. **When onboarding**, read the architecture diagram first so the moving parts
   referenced elsewhere make sense.
3. **In postmortems**, use the incident flowchart to map what actually happened
   against the ideal triage path and find gaps.

## Conventions

- All diagrams use fenced ` ```mermaid ` code blocks.
- Decision-tree leaves point to relative error paths such as
  `../errors/pods/crashloopbackoff.md`.
- Node and edge labels avoid characters that break GitHub's Mermaid parser
  (no unescaped parentheses or pipes inside labels).
