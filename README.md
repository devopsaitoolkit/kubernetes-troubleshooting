<div align="center">

# 🛠️ kubernetes-troubleshooting

### The comprehensive, production-grade Kubernetes troubleshooting knowledge base.

**300+ real production errors. Diagnostic flows. Recovery procedures. Read-only diagnostic scripts. Offline search.**
Written by production SREs, for production SREs.

[![CI](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/actions/workflows/ci.yml/badge.svg)](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/actions/workflows/ci.yml)
[![Link check](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/actions/workflows/link-check.yml/badge.svg)](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/actions/workflows/link-check.yml)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC--BY--4.0-blue.svg)](./LICENSE)
[![Code: MIT](https://img.shields.io/badge/code-MIT-green.svg)](./LICENSE-CODE)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

</div>

---

It's 3 a.m. A pod is in `CrashLoopBackOff`, an alert is firing, and you need the
root cause **now** — not a blog post that stops at "check your logs." This
repository is the reference you keep open during the incident: every page is a
real production failure with the diagnostic flow, the exact `kubectl` commands,
the expected output, the fix, the recovery procedure, and how to stop it
happening again.

> ⭐ **If this saves you during an incident, star the repo** — it helps other
> on-call engineers find it.

## Why this exists

Most Kubernetes troubleshooting content is scattered, shallow, or unsafe (it
tells you to `kubectl delete` things on a production cluster). This project is:

- **Comprehensive** — 300+ errors across 26 subsystems, from `CrashLoopBackOff`
  to etcd quorum loss and admission-webhook failures.
- **Production-safe** — diagnostic commands are **read-only**. Destructive steps
  are clearly marked with their blast radius.
- **Structured & searchable** — every page has consistent frontmatter, so you
  can search the whole library offline with one command.
- **Incident-ready** — each page follows the same battle-tested structure, so
  you always know where to look.

## Quick start

```bash
git clone https://github.com/devopsaitoolkit/kubernetes-troubleshooting.git
cd kubernetes-troubleshooting

# Search the error library (no dependencies — just Python 3.8+)
python tools/search.py CrashLoopBackOff
python tools/search.py "context deadline exceeded"
python tools/search.py --category networking --severity Critical
python tools/search.py --tag dns
```

Or just browse [`docs/errors/`](./docs/errors/) on GitHub.

## What's inside

| Area | What you get |
|------|--------------|
| 📚 [Error library](./docs/errors/) | 300+ pages, one per production error, organized by subsystem |
| 📋 [Playbooks](./docs/playbooks/) | End-to-end incident runbooks (pods won't start, control plane down, storage failures, …) |
| ⌨️ [kubectl reference](./docs/reference/kubectl-troubleshooting.md) | When to use each command, expected output, common mistakes |
| 🗺️ [Cheatsheets](./cheatsheets/) | One-page quick references |
| 📊 [Diagrams](./docs/diagrams/) | Mermaid architecture, decision trees & incident flowcharts |
| 🐍 [Search tool](./tools/) | Offline search + JSON index (powers future API/CLI/MCP) |
| 🔧 [Diagnostic scripts](./scripts/) | **Read-only** cluster snapshot collectors |

### Anatomy of an error page

Every error page follows the same structure so you can scan it under pressure:

`Title` → `Error Message` → `Description` → `Affected Versions` →
`Likely Root Causes` → `Diagnostic Flow` (Mermaid) → `Verification Steps` →
`kubectl Commands` → `Expected Output` → `Common Fixes` →
`Recovery Procedures` → `Validation` → `Prevention` → `Related Errors` →
`References` → `Tags` / `Severity` / `Recovery Time`.

## Error library map

```text
docs/errors/
├── pods/                       ├── rbac/
├── deployments/                ├── security/
├── daemonsets/                 ├── helm/
├── statefulsets/               ├── cert-manager/
├── jobs/                       ├── monitoring/
├── cronjobs/                   ├── autoscaling/
├── nodes/                      ├── api-server/
├── networking/                 ├── etcd/
├── ingress/                    ├── scheduler/
├── services/                   ├── controller-manager/
├── storage/                    ├── admission/
├── persistent-volumes/         ├── kubelet/
├── persistent-volume-claims/   └── container-runtime/
```

Popular pages: [CrashLoopBackOff](./docs/errors/pods/crashloopbackoff.md) ·
[ImagePullBackOff](./docs/errors/pods/imagepullbackoff.md) ·
[OOMKilled](./docs/errors/pods/oomkilled.md) ·
[FailedScheduling](./docs/errors/scheduler/failedscheduling.md) ·
[NodeNotReady](./docs/errors/nodes/nodenotready.md) ·
[Pending pods](./docs/errors/pods/pending.md)

## Diagnostic scripts (read-only)

The scripts in [`scripts/`](./scripts/) collect a snapshot of cluster state for
an incident. **They only read** — they never create, patch, delete, drain,
cordon, scale, or apply anything.

```bash
./scripts/collect-cluster-diagnostics.sh          # broad cluster snapshot
./scripts/gather-pod-logs.sh -n my-app            # logs + describe (incl. --previous)
./scripts/namespace-diagnostics.sh -n my-app      # everything in one namespace
./scripts/storage-diagnostics.sh                  # PV/PVC/CSI snapshot
```

## Target audience

Senior DevOps & Platform Engineers · Site Reliability Engineers · Cloud
Engineers · Kubernetes & OpenShift Administrators · Production on-call
engineers · CKA / CKAD candidates.

## Contributing

This project gets better with every engineer's hard-won experience. Adding an
error page or sharing a war story takes 20 minutes and helps thousands of
on-call engineers.

- 📄 Read the [Contributing Guide](./CONTRIBUTING.md)
- ➕ [Request a new error page](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/issues/new?template=new_error_request.yml)
- 💬 [Share a war story](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/discussions)
- 🧭 See the [Roadmap](./ROADMAP.md) — REST API, CLI, MCP server, VS Code extension

All participants follow our [Code of Conduct](./CODE_OF_CONDUCT.md).

## License

- **Documentation** (everything under `docs/`, plus cheatsheets and diagrams):
  [Creative Commons Attribution 4.0 (CC BY 4.0)](./LICENSE) — use it anywhere,
  just credit the project.
- **Code** (`tools/`, `scripts/`): [MIT License](./LICENSE-CODE).

## Further reading & free resources

This repository is designed to stand entirely on its own. If you want to go
deeper on **AI-assisted** Kubernetes operations, these free resources from the
maintainers help you continue learning:

- 📚 [DevOps & Kubernetes guides](https://devopsaitoolkit.com/blog/)
- 🧪 [Free Kubernetes config validators](https://devopsaitoolkit.com/validators/) (YAML, manifests, Helm)
- 🤖 [AI Incident Response Assistant](https://devopsaitoolkit.com/dashboard/incident-response/)
- 💡 [Kubernetes prompt library](https://devopsaitoolkit.com/prompts/)
- ✉️ [Weekly DevOps newsletter](https://devopsaitoolkit.com/#newsletter)

---

<div align="center">

**Built by on-call engineers who got tired of losing the same battles twice.**
If it helps you, [give it a ⭐](https://github.com/devopsaitoolkit/kubernetes-troubleshooting).

</div>
