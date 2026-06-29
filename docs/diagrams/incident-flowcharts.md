---
title: Incident Response Flowcharts
type: reference
tags:
  - incident-response
  - on-call
  - escalation
  - mermaid
---

# Incident Response Flowcharts

When a cluster is on fire, a repeatable process beats improvisation. These
flowcharts describe the on-call triage workflow and the escalation path so that
anyone holding the pager can move calmly from alert to resolution to learning.

## On-call triage workflow

```mermaid
flowchart TD
    A[Alert / report received] --> B[Detect: confirm it is real]
    B --> B1{Reproducible or measurable?}
    B1 -->|No, single flaky alert| Bx[Acknowledge, watch, silence noise]
    B1 -->|Yes| C[Scope: assess blast radius]

    C --> C1{How many users / services?}
    C1 -->|Single pod / tenant| Sev3[Severity 3]
    C1 -->|One service degraded| Sev2[Severity 2]
    C1 -->|Cluster-wide / data risk| Sev1[Severity 1 + page secondary]

    Sev1 --> D[Diagnose]
    Sev2 --> D
    Sev3 --> D

    D --> D1[Read status, events, logs, dashboards]
    D1 --> D2{Root cause known?}
    D2 -->|No| D3[Use decision trees + error pages]
    D3 --> D2
    D2 -->|Yes| E[Mitigate]

    E --> E1{Fastest safe action?}
    E1 -->|Recent deploy| E2[Roll back]
    E1 -->|Capacity| E3[Scale up / add nodes]
    E1 -->|Bad config| E4[Revert config]
    E1 -->|Dependency| E5[Failover / degrade gracefully]

    E2 --> F[Validate]
    E3 --> F
    E4 --> F
    E5 --> F

    F --> F1{Symptoms cleared and stable?}
    F1 -->|No| D
    F1 -->|Yes| G[Communicate resolution]
    G --> H[Postmortem]
```

### The six stages

1. **Detect.** Confirm the alert reflects real user impact before you wake
   anyone. A single flaky probe is not an incident; a sustained error-rate jump
   is. Acknowledge the page so others know it's being handled.
2. **Scope.** Measure blast radius — one Pod, one service, or the whole
   cluster — and assign a severity. Scope drives both urgency and who you pull
   in. Cluster-wide or data-at-risk situations justify paging a second
   responder immediately.
3. **Diagnose.** Gather evidence: `kubectl get`/`describe`, events, logs,
   metrics, recent change history. Use the
   [decision trees](./troubleshooting-decision-trees.md) and
   [error pages](../errors/) to convert symptoms into a root cause. Loop here
   until you can name the cause.
4. **Mitigate.** Restore service with the fastest *safe* action — usually a
   rollback, a scale-up, or a config revert — even before the permanent fix.
   Stopping the bleeding is more important than elegance.
5. **Validate.** Confirm the symptom is gone and the system is stable, not just
   momentarily quiet. If it isn't, go back to diagnose; a partial fix can mask
   a second cause.
6. **Postmortem.** Once stable, write up the timeline, root cause,
   contributing factors, and action items. Blameless and concrete.

## Escalation tree

```mermaid
flowchart TD
    P[Primary on-call] --> T{Mitigated within target time?}
    T -->|Yes| Done[Resolve and document]
    T -->|No, 15 min Sev1 / 30 min Sev2| S[Engage secondary on-call]

    S --> S1{Need domain expertise?}
    S1 -->|Networking / CNI| NetTeam[Page networking owner]
    S1 -->|Storage / CSI| StoreTeam[Page storage owner]
    S1 -->|Control plane / etcd| PlatTeam[Page platform/SRE lead]
    S1 -->|App-level bug| AppTeam[Page service owner]

    NetTeam --> M{Still unresolved after escalation window?}
    StoreTeam --> M
    PlatTeam --> M
    AppTeam --> M

    M -->|Yes, Sev1 ongoing 60 min| IC[Declare major incident, assign Incident Commander]
    IC --> Comms[Open comms bridge + status page update]
    Comms --> Vendor{Cloud / vendor involved?}
    Vendor -->|Yes| Support[Open priority vendor ticket]
    Vendor -->|No| Continue[Continue with internal experts]
    M -->|No| Done
```

### Escalation principles

- **Time-box every level.** If the primary cannot mitigate within the severity
  target (for example 15 minutes for Sev1), pull in the secondary rather than
  pressing on alone. Escalation is a sign of good judgment, not failure.
- **Escalate by domain.** Route to the team that owns the failing layer —
  networking, storage, control plane, or the application — using the diagnosis
  to choose. Paging the wrong team wastes the window.
- **Declare a major incident** when a Sev1 stays unresolved past the
  escalation window. Assign an Incident Commander whose only job is
  coordination: they run the bridge, keep the timeline, update the status page,
  and decide when to involve the cloud provider.
- **Hand off cleanly.** On long incidents, follow-the-sun handoffs need a
  written current-state summary so the next responder doesn't restart
  diagnosis from zero.

## After the incident

Every Sev1 and Sev2 earns a blameless postmortem within a few business days.
Capture the detection-to-resolution timeline against the workflow above, note
where the process slowed you down (slow detection? wrong escalation?
missing runbook?), and file action items with owners and due dates. The goal is
not to assign blame but to make the next incident shorter — ideally by turning
this one's diagnosis into a new entry in the
[decision trees](./troubleshooting-decision-trees.md) or
[playbooks](../playbooks/).
