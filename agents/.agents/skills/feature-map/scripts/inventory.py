#!/usr/bin/env python3
"""Cheap recon of one or more source trees, used to plan reader scopes before any agent runs.

Usage: python3 inventory.py <dir> [<dir> ...] [--top 25]

Per dir: git state, manifests and stack hints, UI detection, LOC by top-level folder and by extension,
largest source files, and repository docs. Uses `git ls-files` when available so ignored files are skipped.
Prints markdown. Never reads .env files.
"""
import argparse
import json
import subprocess
from collections import Counter
from pathlib import Path

SKIP_DIRS = {"node_modules", ".venv", "venv", "env", "dist", "build", ".git", "__pycache__", ".next",
             ".nuxt", "coverage", "vendor", "target", ".mypy_cache", ".pytest_cache", ".turbo", ".cache"}
SOURCE_EXT = {".py", ".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".vue", ".svelte", ".go", ".rs", ".java",
              ".kt", ".rb", ".php", ".cs", ".scala", ".swift", ".c", ".cc", ".cpp", ".h", ".hpp", ".sql",
              ".html", ".css", ".scss", ".sh", ".tf", ".yaml", ".yml", ".proto", ".graphql"}
UI_EXT = {".vue", ".svelte", ".tsx", ".jsx"}
UI_DEPS = {"react", "vue", "svelte", "@angular/core", "solid-js", "preact", "next", "nuxt", "@sveltejs/kit"}
MANIFESTS = ["package.json", "pyproject.toml", "requirements.txt", "setup.py", "go.mod", "Cargo.toml",
             "pom.xml", "build.gradle", "Gemfile", "composer.json", "Dockerfile", "docker-compose.yml",
             "compose.yaml", "Chart.yaml", "Makefile"]


def git(d, *args):
    r = subprocess.run(["git", "-C", str(d), *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def list_files(d):
    out = git(d, "ls-files")
    if out is not None:
        return [d / p for p in out.splitlines() if (d / p).is_file()]
    files = []
    for p in d.rglob("*"):
        if p.is_file() and not any(part in SKIP_DIRS for part in p.relative_to(d).parts):
            files.append(p)
    return files


def loc(p):
    try:
        with open(p, "rb") as fh:
            return sum(1 for _ in fh)
    except OSError:
        return 0


def report(d, top):
    d = Path(d).resolve()
    print(f"## {d.name}  (`{d}`)\n")
    if git(d, "rev-parse", "--is-inside-work-tree") == "true":
        default = (git(d, "symbolic-ref", "--short", "refs/remotes/origin/HEAD") or "").replace("origin/", "")
        local = git(d, "branch", "--format=%(refname:short)") or ""
        dirty = git(d, "status", "--short") or ""
        print(f"- git: current `{git(d, 'branch', '--show-current') or 'detached'}`, "
              f"origin default `{default or 'unknown'}`, HEAD `{git(d, 'rev-parse', '--short', 'HEAD')}` "
              f"({git(d, 'log', '-1', '--format=%ci')})")
        print(f"- local branches: {', '.join(local.split()) or 'none'}")
        print(f"- uncommitted changes: {len(dirty.splitlines())} paths")
    else:
        print("- git: not a repository")

    files = list_files(d)
    rel = lambda p: p.relative_to(d).as_posix()
    present = [m for m in MANIFESTS if (d / m).exists()]
    print(f"- manifests at root: {', '.join(present) or 'none'}")

    ui_reason = []
    pkg = d / "package.json"
    if pkg.exists():
        try:
            j = json.loads(pkg.read_text(encoding="utf-8"))
            deps = {**j.get("dependencies", {}), **j.get("devDependencies", {})}
            hits = sorted(UI_DEPS & deps.keys())
            if hits:
                ui_reason.append("deps " + ", ".join(hits))
            print(f"- package.json scripts: {', '.join(j.get('scripts', {}).keys()) or 'none'}")
        except ValueError:
            pass
    ui_files = [f for f in files if f.suffix in UI_EXT]
    if ui_files:
        ui_reason.append(f"{len(ui_files)} component files ({', '.join(sorted({f.suffix for f in ui_files}))})")
    print(f"- UI detected: {'yes – ' + '; '.join(ui_reason) if ui_reason else 'no'}")

    src = [(f, loc(f)) for f in files if f.suffix in SOURCE_EXT and ".env" not in f.name]
    total = sum(n for _, n in src)
    print(f"- source files: {len(src)}, lines: {total}\n")

    by_dir, by_ext = Counter(), Counter()
    for f, n in src:
        parts = f.relative_to(d).parts
        by_dir[parts[0] if len(parts) > 1 else "(root files)"] += n
        by_ext[f.suffix] += n
    print("| top-level folder | lines |\n|---|---|")
    for k, n in by_dir.most_common():
        print(f"| `{k}` | {n} |")
    print("\n| extension | lines |\n|---|---|")
    for k, n in by_ext.most_common(12):
        print(f"| `{k}` | {n} |")

    print(f"\nLargest {top} source files:\n\n| file | lines |\n|---|---|")
    for f, n in sorted(src, key=lambda x: -x[1])[:top]:
        print(f"| `{rel(f)}` | {n} |")

    docs = sorted(f for f in files if f.suffix.lower() in {".md", ".rst", ".adoc"})
    print(f"\nRepository docs ({len(docs)}):\n")
    for f in docs[:80]:
        print(f"- `{rel(f)}` ({loc(f)} lines)")
    if len(docs) > 80:
        print(f"- … {len(docs) - 80} more")
    print()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dirs", nargs="+")
    ap.add_argument("--top", type=int, default=25)
    a = ap.parse_args()
    for d in a.dirs:
        report(d, a.top)


if __name__ == "__main__":
    main()
