#!/usr/bin/env python3
"""Mechanical check of every `path:line` cite in a feature map against the baseline snapshots.

Usage:
  python3 check_cites.py --root <feature-map dir> --src backend=<snapshot>/backend --src frontend=<snapshot>/frontend
  [--report <file>]

Checks, per cite:
  missing    – the file cannot be found in any snapshot
  ambiguous  – a bare file name matches several files (cite should be repo-relative)
  range      – a cited line is past the end of the file
It cannot tell whether a claim is true. That stays with the coordinator's spot checks.
"""
import argparse
import re
from collections import defaultdict
from pathlib import Path

CITE = re.compile(
    r"(?<![\w/.@-])((?:[\w.@-]+/)*[\w@-][\w.@-]*\.[A-Za-z][A-Za-z0-9]*)"
    r":(\d+)(?:[-–](\d+))?((?:,\s?\d+(?:[-–]\d+)?)*)"
)


def build_index(srcs):
    by_name = defaultdict(list)
    for _, d in srcs:
        for p in d.rglob("*"):
            if p.is_file():
                by_name[p.name].append(p)
    return by_name


def resolve(path, srcs, by_name):
    if "/" not in path:  # bare file name: every match counts, so duplicates show up as ambiguous
        return by_name.get(path, [])
    for name, d in srcs:
        if path.startswith(name + "/") and (d / path[len(name) + 1:]).is_file():
            return [d / path[len(name) + 1:]]
        if (d / path).is_file():
            return [d / path]
    cands = [p for p in by_name.get(Path(path).name, []) if p.as_posix().endswith(path)]
    return cands


def ranges(m):
    out = [(int(m.group(2)), int(m.group(3) or m.group(2)))]
    for part in re.findall(r"\d+(?:[-–]\d+)?", m.group(4) or ""):
        a, _, b = part.replace("–", "-").partition("-")
        out.append((int(a), int(b or a)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--src", action="append", required=True, help="name=dir, repeatable")
    ap.add_argument("--report")
    a = ap.parse_args()

    srcs = [(s.split("=", 1)[0], Path(s.split("=", 1)[1]).resolve()) for s in a.src]
    by_name = build_index(srcs)
    cache, problems, total = {}, [], 0

    for md in sorted(Path(a.root).resolve().rglob("*.md")):
        rel_md = md.relative_to(Path(a.root).resolve()).as_posix()
        if rel_md.startswith(("_", ".")):
            continue
        for ln, line in enumerate(md.read_text(encoding="utf-8").splitlines(), 1):
            for m in CITE.finditer(line):
                if "://" in line[max(0, m.start() - 12):m.start()]:
                    continue
                total += 1
                where = f"{rel_md}:{ln}"
                found = resolve(m.group(1), srcs, by_name)
                if not found:
                    problems.append(("missing", where, m.group(0)))
                    continue
                if len(found) > 1:
                    problems.append(("ambiguous", where, f"{m.group(0)} ({len(found)} files)"))
                    continue
                f = found[0]
                if f not in cache:
                    cache[f] = f.read_text(encoding="utf-8", errors="replace").splitlines()
                src_lines = cache[f]
                rs = ranges(m)
                if any(b > len(src_lines) for _, b in rs):
                    problems.append(("range", where, f"{m.group(0)} (file has {len(src_lines)} lines)"))

    counts = defaultdict(int)
    for kind, *_ in problems:
        counts[kind] += 1
    print(f"cites checked: {total}; " + ", ".join(f"{k}: {v}" for k, v in sorted(counts.items())) if counts
          else f"cites checked: {total}; no problems")
    lines = [f"{k}\t{w}\t{d}" for k, w, d in problems]
    if a.report:
        Path(a.report).write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"full list: {a.report}")
    else:
        print("\n".join(lines[:60]))
        if len(lines) > 60:
            print(f"… {len(lines) - 60} more (use --report)")


if __name__ == "__main__":
    main()
