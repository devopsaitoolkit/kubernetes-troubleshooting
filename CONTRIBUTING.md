# Contributing to kubernetes-troubleshooting

First off — **thank you**. Every error you document, every fix you sharpen, and
every war story you share makes on-call life better for the next engineer. This
project is built by production engineers, for production engineers.

There are many ways to contribute:

- 📝 **Add a new error page** (the most valuable contribution)
- 🔧 **Fix or improve an existing page** — a better diagnostic step, a real
  command, a clearer root cause
- 📚 **Write or improve a playbook**
- 🐍 **Improve the search tool or diagnostic scripts**
- 🐛 **Report a problem** via an issue
- 💬 **Share a troubleshooting story** in Discussions

## Ground rules

1. **Be technically accurate.** Prefer first-hand production experience and the
   official Kubernetes docs over guesswork. Cite versions when behavior differs.
2. **Be production-safe.** Diagnostic commands must be **read-only**. Any
   destructive or disruptive step (restart, delete, drain, scale, rollback)
   must be clearly marked with its blast radius and a safer alternative where
   one exists.
3. **Educate first.** This is a troubleshooting resource, not a marketing
   channel. Links to external resources belong only in "Further Reading" /
   "Related Resources" sections — never inside diagnostic steps.
4. **One error per page.** Each page should target a single, specific failure
   and one primary search phrase.

## Adding a new error page

1. Copy the template:

   ```bash
   cp docs/errors/_TEMPLATE.md docs/errors/<category>/<error-slug>.md
   ```

   Use a lowercase, hyphenated slug, e.g. `crashloopbackoff.md`,
   `failed-to-pull-image.md`.

2. Fill in **every** section. Pages with `TODO`s or empty sections will not be
   merged. Required frontmatter:

   ```yaml
   ---
   title: "Human-Readable Error Name"
   error_message: "The exact error string"
   category: pods            # must match the directory
   severity: High            # Critical | High | Medium | Low
   recovery_time: "5–30 min"
   k8s_versions: "1.20+"
   tags: [pods, restart]
   related: ["ImagePullBackOff"]
   ---
   ```

3. Required body sections (in order): **Error Message, Description, Affected
   Kubernetes Versions, Likely Root Causes, Diagnostic Flow, Verification
   Steps, kubectl Commands, Expected Output, Common Fixes, Recovery
   Procedures, Validation, Prevention, Related Errors, References.**

4. Rebuild the search index and run the checks locally:

   ```bash
   python tools/build_index.py
   python -m unittest discover -s tools/tests
   ```

5. Open a pull request using the PR template.

## Style

- Write from a senior SRE's perspective: calm, specific, incident-ready.
- Use fenced code blocks with a language hint (` ```bash `, ` ```text `,
  ` ```yaml `).
- Diagrams use **Mermaid** so they render natively on GitHub.
- Keep lines readable; long command lines are fine.
- American English; the spell-checker dictionary lives in `.cspell.json` —
  add genuinely new technical terms there.

## Local checks

| Check | Command |
|-------|---------|
| Search index up to date | `python tools/build_index.py --check` |
| Unit tests | `python -m unittest discover -s tools/tests` |
| Markdown lint | `npx markdownlint-cli2 "**/*.md"` |
| Spell check | `npx cspell "**/*.md"` |
| Link check | `npx markdown-link-check docs/**/*.md` |

CI runs all of these on every pull request.

## Developer Certificate of Origin

By contributing, you certify that your contribution is your own work (or you
have the right to submit it) and that you license it under the project's terms:
documentation under **CC BY 4.0** and code under the **MIT License**.

## Questions?

Open a [Discussion](https://github.com/devopsaitoolkit/kubernetes-troubleshooting/discussions)
— no question about a production incident is too small.
