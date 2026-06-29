# Tools

Offline, dependency-free utilities for searching the error library. **Runtime
dependencies: none** (Python 3.8+ standard library only).

## `search.py` — search the error library

```bash
python tools/search.py CrashLoopBackOff            # free-text
python tools/search.py "context deadline exceeded" # phrase
python tools/search.py --category networking       # by subsystem
python tools/search.py --severity Critical         # by severity
python tools/search.py --tag dns --severity High   # combine filters
python tools/search.py --recovery "<5 min"         # by recovery time
python tools/search.py oom --json                  # machine-readable
python tools/search.py --list-categories           # discover facets
python tools/search.py --list-tags
```

The tool reads the Markdown files under `docs/errors/` and their YAML
frontmatter. It never touches a cluster.

## `build_index.py` — generate `index.json`

```bash
python tools/build_index.py            # write tools/index.json
python tools/build_index.py --check    # CI: fail if index.json is stale
python tools/build_index.py --stdout   # print, write nothing
```

`index.json` is the machine-readable index of the whole library. It's the
foundation for the planned REST API, CLI, MCP server, and VS Code extension
(see the [Roadmap](../ROADMAP.md)). **Regenerate and commit it whenever you add
or edit an error page.**

## Tests

```bash
python -m unittest discover -s tools/tests        # stdlib, no deps
# or, with pytest:
pip install -r tools/requirements-dev.txt && pytest -q tools/tests
```

## Index schema (v1)

```jsonc
{
  "schema": 1,
  "count": 338,
  "by_category": { "pods": 40, "nodes": 22, ... },
  "by_severity": { "Critical": 70, "High": 150, ... },
  "errors": [
    {
      "title": "CrashLoopBackOff",
      "error_message": "Back-off restarting failed container",
      "category": "pods",
      "severity": "High",
      "recovery_time": "5-30 min",
      "k8s_versions": "1.20+",
      "tags": ["pods", "restart", "crashloop"],
      "related": ["OOMKilled"],
      "path": "docs/errors/pods/crashloopbackoff.md"
    }
  ]
}
```
