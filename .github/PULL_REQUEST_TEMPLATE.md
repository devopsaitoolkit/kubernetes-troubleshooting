<!-- Thanks for contributing! Please complete this checklist. -->

## What does this PR do?

<!-- A new error page? A fix? A new playbook? A tooling change? -->

## Related issue

<!-- e.g. Closes #123 -->

## Type

- [ ] New error page
- [ ] Fix/improve an existing page
- [ ] New or updated playbook
- [ ] Tooling (search / scripts / CI)
- [ ] Other

## Checklist

- [ ] One error per page; the page targets a single primary search phrase.
- [ ] **All sections are filled in** — no `TODO`s or empty headings.
- [ ] Frontmatter is complete (`title`, `error_message`, `category`,
      `severity`, `recovery_time`, `k8s_versions`, `tags`, `related`).
- [ ] **Diagnostic commands are read-only.** Any destructive/disruptive step is
      clearly marked with its blast radius.
- [ ] No secrets, kubeconfigs, real cluster names, IPs, or customer data.
- [ ] Promotional links (if any) are only in "Further Reading" / "Related
      Resources" — never inside diagnostic steps.
- [ ] I ran `python tools/build_index.py` and committed the updated
      `tools/index.json` (if I added/changed an error page).
- [ ] I ran the local checks (`python -m unittest discover -s tools/tests`).

## Notes for reviewers

<!-- Anything that needs special attention. -->
