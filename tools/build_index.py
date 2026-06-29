#!/usr/bin/env python3
"""
Build a machine-readable index of the error library.

Walks ``docs/errors/`` and writes ``tools/index.json`` — a flat list of every
error's frontmatter plus its path. The index powers fast lookups for future
interfaces (REST API, VS Code extension, MCP server, static site search) and
is validated in CI.

Usage:
    python tools/build_index.py            # writes tools/index.json
    python tools/build_index.py --check    # fail if index.json is stale
    python tools/build_index.py --stdout   # print to stdout, write nothing
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict
from pathlib import Path

from search import load_docs, REPO_ROOT  # type: ignore

INDEX_PATH = REPO_ROOT / "tools" / "index.json"


def build() -> dict:
    docs = load_docs()
    by_category: dict[str, int] = {}
    by_severity: dict[str, int] = {}
    for d in docs:
        by_category[d.category] = by_category.get(d.category, 0) + 1
        if d.severity:
            by_severity[d.severity] = by_severity.get(d.severity, 0) + 1
    return {
        "schema": 1,
        "count": len(docs),
        "by_category": dict(sorted(by_category.items())),
        "by_severity": dict(sorted(by_severity.items())),
        "errors": [asdict(d) for d in docs],
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true",
                    help="exit non-zero if the committed index is out of date")
    ap.add_argument("--stdout", action="store_true",
                    help="print the index instead of writing it")
    args = ap.parse_args(argv)

    index = build()
    payload = json.dumps(index, indent=2) + "\n"

    if args.stdout:
        sys.stdout.write(payload)
        return 0

    if args.check:
        current = INDEX_PATH.read_text(encoding="utf-8") if INDEX_PATH.exists() else ""
        if current != payload:
            print("index.json is stale — run `python tools/build_index.py`",
                  file=sys.stderr)
            return 1
        print(f"index.json is up to date ({index['count']} errors).")
        return 0

    INDEX_PATH.write_text(payload, encoding="utf-8")
    print(f"Wrote {INDEX_PATH.relative_to(REPO_ROOT)} ({index['count']} errors).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
