# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial public release of the Kubernetes troubleshooting knowledge base.
- 300+ structured production-error pages across 26 subsystems
  (pods, deployments, daemonsets, statefulsets, jobs, cronjobs, nodes,
  networking, ingress, services, storage, persistent volumes & claims, RBAC,
  security, helm, cert-manager, monitoring, autoscaling, api-server, etcd,
  scheduler, controller-manager, admission, kubelet, container-runtime).
- Incident playbooks for the major failure domains.
- Extensive `kubectl` troubleshooting reference and cheatsheets.
- Mermaid diagrams: architecture, decision trees, and incident flowcharts.
- Offline, dependency-free Python search tool (`tools/search.py`) and a
  generated `tools/index.json`.
- Read-only cluster diagnostic scripts (`scripts/`).
- GitHub community health files, issue/PR/discussion templates, and CI
  (markdown lint, link check, spell check, index validation, unit tests).

[Unreleased]: https://github.com/devopsaitoolkit/kubernetes-troubleshooting/commits/main
