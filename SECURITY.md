# Security Policy

## Scope

This repository contains **documentation** and **read-only diagnostic tooling**.
It does not run services or handle user data. The most important security
properties are:

1. **The diagnostic scripts in `scripts/` must remain strictly read-only.**
   They may only run non-mutating `kubectl` verbs (`get`, `describe`, `logs`,
   `top`, `version`, `api-resources`, etc.). A script that creates, patches,
   deletes, drains, cordons, scales, or applies anything is a security bug.
2. **Documentation must not recommend destructive actions** without a clear
   warning and a description of the blast radius.
3. **No secrets, kubeconfigs, real cluster names, IPs, or customer data** may be
   committed. Sample logs are synthetic.

## Reporting a Vulnerability

If you find:

- a script that performs (or can be coerced into) a mutating cluster operation,
- documentation that would cause data loss or a security regression if followed,
- leaked secrets or sensitive data in the repository history, or
- a supply-chain issue in the tooling,

please report it privately:

- **Email:** admin@devopsaitoolkit.com
- Or use **GitHub → Security → Report a vulnerability** (private advisory).

Please do **not** open a public issue for sensitive reports. We aim to
acknowledge reports within 3 business days and to publish a fix or mitigation as
quickly as is practical.

## Supported Versions

This is a rolling documentation project; the `main` branch is the supported
version. Tagged releases are snapshots of `main`.
