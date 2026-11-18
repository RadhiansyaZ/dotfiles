#!/usr/bin/env python3
"""Collect every "Doc vs code" section from technical/**/*.md into technical/doc-vs-code.md.

Usage: python3 collect_doc_vs_code.py --root <feature-map dir>

Everything above the GENERATED marker in technical/doc-vs-code.md is kept as a hand-written preface
(baseline caveats, largest conflicts). Everything below it is regenerated on each run.
"""
import argparse
import re
from pathlib import Path

MARKER = "<!-- GENERATED BELOW: edit module docs, then re-run collect_doc_vs_code.py -->"
DEFAULT_PREFACE = """# Doc vs code – conflict log

Where a repository document and the code disagree, the code is the source of truth. This file collects
every conflict the readers found, grouped by the module doc that reported it. Nothing in the repositories
was changed.
"""


def sections(lines):
    """Yield (parent heading, body) for each heading that contains 'doc vs code'."""
    i = 0
    while i < len(lines):
        m = re.match(r"^(#+)\s.*doc vs code", lines[i], re.I)
        if not m:
            i += 1
            continue
        level = len(m.group(1))
        parent = next((re.sub(r"^#+\s*", "", l) for l in reversed(lines[:i])
                       if re.match(rf"^#{{1,{level - 1}}}\s", l)), "") if level > 1 else ""
        j, fenced, body = i + 1, False, []
        while j < len(lines):
            if lines[j].startswith("```"):
                fenced = not fenced
            h = re.match(r"^(#+)\s", lines[j])
            if h and not fenced and len(h.group(1)) <= level:
                break
            body.append(lines[j])
            j += 1
        text = "\n".join(body).strip()
        if text:
            yield parent, text
        i = j


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    root = Path(ap.parse_args().root).resolve()
    tech = root / "technical"
    out = tech / "doc-vs-code.md"

    preface = DEFAULT_PREFACE
    if out.exists():
        old = out.read_text(encoding="utf-8")
        preface = old.split(MARKER)[0] if MARKER in old else preface

    parts, count = [preface.rstrip(), "", MARKER, ""], 0
    for f in sorted(tech.rglob("*.md")):
        if f == out:
            continue
        blocks = list(sections(f.read_text(encoding="utf-8").splitlines()))
        if not blocks:
            continue
        rel = f.relative_to(tech).as_posix()
        parts += [f"## {rel}", "", f"Source: [{rel}]({rel})", ""]
        for parent, text in blocks:
            if parent and len(blocks) > 1:
                parts += [f"### {parent}", ""]
            parts += [text, ""]
            count += 1

    tech.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(parts).rstrip() + "\n", encoding="utf-8")
    print(f"wrote {out} ({count} sections)")


if __name__ == "__main__":
    main()
