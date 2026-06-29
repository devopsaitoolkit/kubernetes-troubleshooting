"""
Tests for the offline error-library search tool.

Run with:
    cd tools && python -m pytest -q
or with the stdlib only:
    python -m unittest discover -s tools/tests
"""
import sys
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS))

import search  # noqa: E402


SAMPLE = """---
title: "CrashLoopBackOff"
error_message: "Back-off restarting failed container"
category: pods
severity: High
recovery_time: "5-30 min"
k8s_versions: "1.20+"
tags: [pods, restart, crashloop]
related: ["OOMKilled", "ImagePullBackOff"]
---

# CrashLoopBackOff
body
"""


class TestFrontmatter(unittest.TestCase):
    def test_parses_scalars_and_lists(self):
        fm = search.parse_frontmatter(SAMPLE)
        self.assertEqual(fm["title"], "CrashLoopBackOff")
        self.assertEqual(fm["severity"], "High")
        self.assertEqual(fm["tags"], ["pods", "restart", "crashloop"])
        self.assertIn("OOMKilled", fm["related"])

    def test_no_frontmatter(self):
        self.assertEqual(search.parse_frontmatter("# just a heading"), {})

    def test_quoted_values_unwrapped(self):
        fm = search.parse_frontmatter(SAMPLE)
        self.assertNotIn('"', fm["error_message"])


def _docs():
    return [
        search.ErrorDoc(
            title="CrashLoopBackOff",
            error_message="Back-off restarting failed container",
            category="pods", severity="High", recovery_time="5-30 min",
            k8s_versions="1.20+", tags=["pods", "restart", "crashloop"],
            related=["OOMKilled"], path="docs/errors/pods/crashloopbackoff.md",
        ),
        search.ErrorDoc(
            title="NodeNotReady", error_message="node status is NotReady",
            category="nodes", severity="Critical", recovery_time="10-60 min",
            k8s_versions="1.20+", tags=["nodes", "kubelet"], related=[],
            path="docs/errors/nodes/nodenotready.md",
        ),
    ]


class TestSearch(unittest.TestCase):
    def test_free_text_match(self):
        r = search.search(_docs(), terms=["crashloop"])
        self.assertEqual(len(r), 1)
        self.assertEqual(r[0].title, "CrashLoopBackOff")

    def test_category_filter(self):
        r = search.search(_docs(), category="nodes")
        self.assertEqual(len(r), 1)
        self.assertEqual(r[0].title, "NodeNotReady")

    def test_severity_filter(self):
        r = search.search(_docs(), severity="Critical")
        self.assertEqual([d.title for d in r], ["NodeNotReady"])

    def test_tag_filter(self):
        r = search.search(_docs(), tag="kubelet")
        self.assertEqual(len(r), 1)

    def test_no_match(self):
        self.assertEqual(search.search(_docs(), terms=["nonexistent"]), [])

    def test_critical_sorts_first(self):
        r = search.search(_docs())
        self.assertEqual(r[0].severity, "Critical")


class TestRealLibrary(unittest.TestCase):
    """Smoke test against the actual repo content, if present."""

    def test_library_loads(self):
        docs = search.load_docs()
        # The repo ships hundreds of errors; allow this to pass pre-content too.
        self.assertIsInstance(docs, list)
        for d in docs:
            self.assertTrue(d.title, f"empty title in {d.path}")
            self.assertTrue(d.severity, f"missing severity in {d.path}")


if __name__ == "__main__":
    unittest.main()
