#!/usr/bin/env python3
"""Build one self-contained, offline feature-map.html from the .md tree of a feature map.

Usage:
  python3 build_html.py --root <feature-map dir> --title "Neuro Feature Map" \
      [--subtitle "As built on main"] [--label "docs/feature-map/"] [--out <file>]

Navigation comes from <root>/nav.json when present:
  [{"group": "Business", "items": ["business/journeys.md", ...]}, ...]
Otherwise it is derived from the folder layout (README, business/, technical/, technical/<sub>/).
Markdown sources, marked and mermaid are inlined, so the file opens without a network.
"""
import argparse
import json
import re
from pathlib import Path

SKILL = Path(__file__).resolve().parent.parent
VENDOR = SKILL / "assets/vendor"
TEMPLATE = SKILL / "assets/template.html"

# Preferred order inside auto-generated groups; anything else follows alphabetically.
PREFERRED = {
    "business": ["journeys.md", "feature-inventory.md", "reference-alignment.md"],
    "technical": ["overview.md", "flows.md", "doc-vs-code.md"],
}


def auto_nav(root):
    def ordered(folder, key):
        files = sorted(p.name for p in folder.glob("*.md")) if folder.is_dir() else []
        first = [f for f in PREFERRED.get(key, []) if f in files]
        return first + [f for f in files if f not in first]

    nav = []
    if (root / "README.md").exists():
        nav.append({"group": "Start here", "items": ["README.md"]})
    if (root / "business").is_dir():
        nav.append({"group": "Business", "items": [f"business/{f}" for f in ordered(root / "business", "business")]})
    tech = root / "technical"
    if tech.is_dir():
        top = ordered(tech, "technical")
        if top:
            nav.append({"group": "Technical – cross-cutting", "items": [f"technical/{f}" for f in top]})
        for sub in sorted(p for p in tech.iterdir() if p.is_dir()):
            items = [f"technical/{sub.name}/{f}" for f in ordered(sub, sub.name)]
            if items:
                nav.append({"group": f"Technical – {sub.name}", "items": items})
    return nav


def title_of(text, fallback):
    m = re.search(r"^#\s+(.+)$", text, re.M)
    return m.group(1).strip().replace("`", "") if m else fallback


def inline_js(path):
    return path.read_text(encoding="utf-8").replace("</script", "<\\/script")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--subtitle", default="As built – business and technical")
    ap.add_argument("--label", default="", help="prefix shown above each doc, e.g. docs/feature-map/")
    ap.add_argument("--out")
    a = ap.parse_args()

    root = Path(a.root).resolve()
    nav_file = root / "nav.json"
    raw_nav = json.loads(nav_file.read_text(encoding="utf-8")) if nav_file.exists() else auto_nav(root)

    docs, nav, missing = {}, [], []
    for group in raw_nav:
        items = []
        for p in group["items"]:
            f = root / p
            if not f.exists():
                missing.append(p)
                continue
            text = f.read_text(encoding="utf-8")
            docs[p] = text
            items.append({"path": p, "title": title_of(text, p)})
        if items:
            nav.append({"group": group["group"], "items": items})

    unlisted = sorted(
        str(f.relative_to(root)) for f in root.rglob("*.md")
        if str(f.relative_to(root)) not in docs and not f.relative_to(root).parts[0].startswith(("_", "."))
    )

    esc = lambda s: s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    meta = {"title": a.title, "label": a.label}
    data = json.dumps({"docs": docs, "nav": nav, "meta": meta}, ensure_ascii=False).replace("</", "<\\/")
    html = (
        TEMPLATE.read_text(encoding="utf-8")
        .replace("__TITLE__", esc(a.title))
        .replace("__SUBTITLE__", esc(a.subtitle))
        .replace("/*__MARKED__*/", inline_js(VENDOR / "marked.umd.js"))
        .replace("/*__MERMAID__*/", inline_js(VENDOR / "mermaid.min.js"))
        .replace("/*__DATA__*/null", data)
    )
    out = Path(a.out).resolve() if a.out else root / "feature-map.html"
    out.write_text(html, encoding="utf-8")
    print(f"wrote {out} ({out.stat().st_size // 1024} KB), {len(docs)} docs")
    if missing:
        print("missing (in nav, not on disk):", ", ".join(missing))
    if unlisted:
        print("not in nav:", ", ".join(unlisted))


if __name__ == "__main__":
    main()
