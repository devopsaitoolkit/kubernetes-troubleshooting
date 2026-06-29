#!/usr/bin/env python3
"""
kubernetes-troubleshooting search
=================================

Search the error library by message, keyword, resource type, severity,
technology, tags, or recovery time — entirely offline, with no third-party
dependencies (Python 3.8+).

Examples
--------
    python search.py CrashLoopBackOff
    python search.py "context deadline exceeded"
    python search.py --category networking
    python search.py --severity Critical
    python search.py --tag dns --severity High
    python search.py --recovery "<5 min"
    python search.py --list-categories
    python search.py oom --json

The search is run against the Markdown files under ``docs/errors/`` and the
YAML frontmatter at the top of each file. No cluster access is required and
nothing is ever modified.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parent.parent
ERRORS_DIR = REPO_ROOT / "docs" / "errors"

SEVERITY_ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3}


# --------------------------------------------------------------------------- #
# Minimal, dependency-free YAML frontmatter parser.
# Handles the small subset we use: scalars and inline ``[a, b]`` lists.
# --------------------------------------------------------------------------- #
def _parse_scalar(value: str):
    value = value.strip()
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [_unquote(v.strip()) for v in _split_top_level(inner)]
    return _unquote(value)


def _split_top_level(text: str) -> list[str]:
    parts, depth, current = [], 0, []
    for ch in text:
        if ch in "[":
            depth += 1
        elif ch in "]":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(ch)
    if current:
        parts.append("".join(current))
    return parts


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_frontmatter(text: str) -> dict:
    """Return the YAML frontmatter block of a Markdown file as a dict."""
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end].strip("\n")
    data: dict = {}
    key = None
    for line in block.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if re.match(r"^\s*-\s+", line) and key:  # block list item
            data.setdefault(key, [])
            if isinstance(data[key], list):
                data[key].append(_unquote(re.sub(r"^\s*-\s+", "", line)))
            continue
        m = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", line)
        if m:
            key, raw = m.group(1), m.group(2)
            data[key] = _parse_scalar(raw) if raw.strip() else []
    return data


# --------------------------------------------------------------------------- #
# Data model
# --------------------------------------------------------------------------- #
@dataclass
class ErrorDoc:
    title: str
    error_message: str
    category: str
    severity: str
    recovery_time: str
    k8s_versions: str
    tags: list[str] = field(default_factory=list)
    related: list[str] = field(default_factory=list)
    path: str = ""

    @property
    def haystack(self) -> str:
        return " ".join(
            [
                self.title,
                self.error_message,
                self.category,
                self.severity,
                self.recovery_time,
                " ".join(self.tags),
                " ".join(self.related),
                self.path,
            ]
        ).lower()


def load_docs(errors_dir: Path = ERRORS_DIR) -> list[ErrorDoc]:
    docs: list[ErrorDoc] = []
    if not errors_dir.exists():
        return docs
    for md in sorted(errors_dir.rglob("*.md")):
        if md.name.startswith("_"):  # templates / partials
            continue
        fm = parse_frontmatter(md.read_text(encoding="utf-8", errors="replace"))
        if not fm.get("title"):
            continue
        docs.append(
            ErrorDoc(
                title=str(fm.get("title", "")),
                error_message=str(fm.get("error_message", "")),
                category=str(fm.get("category", md.parent.name)),
                severity=str(fm.get("severity", "")),
                recovery_time=str(fm.get("recovery_time", "")),
                k8s_versions=str(fm.get("k8s_versions", "")),
                tags=_as_list(fm.get("tags")),
                related=_as_list(fm.get("related")),
                path=str(md.relative_to(REPO_ROOT)),
            )
        )
    return docs


def _as_list(value) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v) for v in value]
    return [str(value)]


# --------------------------------------------------------------------------- #
# Filtering / ranking
# --------------------------------------------------------------------------- #
def search(
    docs: Iterable[ErrorDoc],
    terms: list[str] | None = None,
    category: str | None = None,
    severity: str | None = None,
    tag: str | None = None,
    recovery: str | None = None,
) -> list[ErrorDoc]:
    results = []
    query = " ".join(terms).lower().strip() if terms else ""
    for doc in docs:
        if category and doc.category.lower() != category.lower():
            continue
        if severity and doc.severity.lower() != severity.lower():
            continue
        if tag and tag.lower() not in [t.lower() for t in doc.tags]:
            continue
        if recovery and recovery.lower() not in doc.recovery_time.lower():
            continue
        if query and query not in doc.haystack:
            # also allow all-words-present matching for multi-word queries
            if not all(word in doc.haystack for word in query.split()):
                continue
        results.append(doc)

    def sort_key(d: ErrorDoc):
        exact = 0 if query and (query == d.title.lower()
                                or query in d.error_message.lower()) else 1
        return (exact, SEVERITY_ORDER.get(d.severity.lower(), 9), d.title.lower())

    return sorted(results, key=sort_key)


# --------------------------------------------------------------------------- #
# Output
# --------------------------------------------------------------------------- #
SEV_COLOR = {"critical": "\033[91m", "high": "\033[93m",
             "medium": "\033[96m", "low": "\033[92m"}
RESET = "\033[0m"


def _color(text: str, sev: str, enabled: bool) -> str:
    if not enabled:
        return text
    return f"{SEV_COLOR.get(sev.lower(), '')}{text}{RESET}"


def render(results: list[ErrorDoc], color: bool) -> str:
    if not results:
        return "No matching errors found. Try a broader keyword or --list-tags."
    lines = [f"Found {len(results)} matching error(s):\n"]
    for d in results:
        sev = _color(f"[{d.severity or '?'}]", d.severity, color)
        lines.append(f"  {sev} {d.title}")
        if d.error_message:
            lines.append(f"      message : {d.error_message}")
        lines.append(f"      category: {d.category}   recovery: {d.recovery_time or 'n/a'}")
        if d.tags:
            lines.append(f"      tags    : {', '.join(d.tags)}")
        lines.append(f"      doc     : {d.path}")
        lines.append("")
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Search the Kubernetes troubleshooting error library (offline).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("query", nargs="*", help="free-text terms (error message or keyword)")
    p.add_argument("--category", "-c", help="filter by resource type / directory")
    p.add_argument("--severity", "-s", help="Critical | High | Medium | Low")
    p.add_argument("--tag", "-t", help="filter by a single tag")
    p.add_argument("--recovery", "-r", help="substring match on recovery time")
    p.add_argument("--json", action="store_true", help="machine-readable output")
    p.add_argument("--no-color", action="store_true", help="disable ANSI colors")
    p.add_argument("--list-categories", action="store_true")
    p.add_argument("--list-tags", action="store_true")
    p.add_argument("--list-severities", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    docs = load_docs()
    if not docs:
        print("No error docs found under docs/errors/. Is this the repo root?",
              file=sys.stderr)
        return 2

    if args.list_categories:
        for c in sorted({d.category for d in docs}):
            print(c)
        return 0
    if args.list_tags:
        tags = sorted({t for d in docs for t in d.tags})
        for t in tags:
            print(t)
        return 0
    if args.list_severities:
        for s in sorted({d.severity for d in docs if d.severity},
                        key=lambda x: SEVERITY_ORDER.get(x.lower(), 9)):
            print(s)
        return 0

    results = search(
        docs,
        terms=args.query,
        category=args.category,
        severity=args.severity,
        tag=args.tag,
        recovery=args.recovery,
    )

    if args.json:
        print(json.dumps([asdict(d) for d in results], indent=2))
    else:
        color = sys.stdout.isatty() and not args.no_color
        print(render(results, color))
    return 0 if results else 1


if __name__ == "__main__":
    raise SystemExit(main())
