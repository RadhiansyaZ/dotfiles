#!/usr/bin/env python3
"""Open every page of a built feature-map.html in headless Chromium and check that Mermaid diagrams render.

Usage: python3 render_check.py --html <feature-map.html> [--jobs 4]
Exit 0 all good, 1 a diagram failed or is missing, 2 no headless browser found (skip and say so).
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

BROWSERS = ["chromium", "chromium-browser", "google-chrome", "google-chrome-stable", "chrome"]
ERR = re.compile(r'class="mermaid-err">Diagram could not be drawn: (?!\$\{)([^<]{0,300})')
SVG = '<div class="mermaid-box"><svg'


def load_data(html):
    i = html.index("const DATA = ") + len("const DATA = ")
    data, _ = json.JSONDecoder().raw_decode(html[i:].replace("<\\/", "</"))
    return data


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--html", required=True)
    ap.add_argument("--jobs", type=int, default=4)
    a = ap.parse_args()
    browser = next((b for b in map(shutil.which, BROWSERS) if b), None)
    if not browser:
        print("no headless Chromium/Chrome found – render check skipped")
        sys.exit(2)

    path = Path(a.html).resolve()
    data = load_data(path.read_text(encoding="utf-8"))
    pages = [i["path"] for g in data["nav"] for i in g["items"]]

    def check(p):
        slug = re.sub(r"[^A-Za-z0-9]+", "-", re.sub(r"\.md$", "", p))
        want = data["docs"][p].count("```mermaid")
        try:
            dom = subprocess.run(
                [browser, "--headless=new", "--no-sandbox", "--disable-gpu", "--virtual-time-budget=20000",
                 "--dump-dom", f"{path.as_uri()}#{slug}"],
                capture_output=True, text=True, timeout=120).stdout
        except subprocess.TimeoutExpired:
            return p, want, -1, ["timeout"]
        return p, want, dom.count(SVG), ERR.findall(dom)

    bad = 0
    with ThreadPoolExecutor(a.jobs) as ex:
        for p, want, got, errs in ex.map(check, pages):
            ok = not errs and got == want
            bad += not ok
            if not ok or want:
                print(f"{'ok ' if ok else 'BAD'} {p}: mermaid {got}/{want}" + (f" – {errs[0][:200]}" if errs else ""))
    print(f"{len(pages)} pages, {bad} with problems")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
