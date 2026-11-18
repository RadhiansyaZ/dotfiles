#!/usr/bin/env python3
"""Lint a feature map before it is built: style and leak checks.

Usage: python3 lint_docs.py --root <feature-map dir>
Exit 1 when an error is found. Errors: em dash, scratchpad or /tmp path, secret-like string, file with no H1.
Warnings: absolute home paths, docs with no cite at all, unbalanced code fences.
"""
import argparse
import re
import sys
from pathlib import Path

SECRET = [
    re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}"),  # JWT
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"(?i)\b(api[_-]?key|secret|password|passwd|token|bearer)\b\s*[=:]\s*['\"]?[A-Za-z0-9_\-/+]{16,}"),
    re.compile(r"\b(sk|pk|rk)-[A-Za-z0-9]{20,}"),
]
CITE = re.compile(r"[\w.-]+\.[A-Za-z][A-Za-z0-9]*:\d+")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    root = Path(ap.parse_args().root).resolve()
    errors, warns = [], []
    for md in sorted(root.rglob("*.md")):
        rel = md.relative_to(root).as_posix()
        if rel.startswith(("_", ".")):
            continue
        text = md.read_text(encoding="utf-8")
        if not re.search(r"^#\s", text, re.M):
            errors.append(f"{rel}: no H1 title")
        if text.count("```") % 2:
            warns.append(f"{rel}: odd number of ``` fences")
        if rel != "README.md" and not CITE.search(text):
            warns.append(f"{rel}: no file:line cite found")
        for ln, line in enumerate(text.splitlines(), 1):
            if "—" in line:
                errors.append(f"{rel}:{ln}: em dash")
            if "/tmp/" in line or "scratchpad" in line:
                errors.append(f"{rel}:{ln}: temp path")
            if re.search(r"/home/[\w.-]+/|/Users/[\w.-]+/|C:\\\\Users\\\\", line):
                warns.append(f"{rel}:{ln}: absolute home path")
            for p in SECRET:
                if p.search(line):
                    errors.append(f"{rel}:{ln}: secret-like string ({p.pattern[:24]}…)")
    for e in errors:
        print("ERROR", e)
    for w in warns:
        print("warn ", w)
    print(f"{len(errors)} errors, {len(warns)} warnings")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
