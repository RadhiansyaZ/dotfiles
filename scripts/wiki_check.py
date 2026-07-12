#!/usr/bin/env python3
"""Validate the repository's source-backed Markdown wiki."""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
WIKI = ROOT / "docs/wiki"
MAP_FILE = WIKI / "_meta/source-map.yml"
PENDING = WIKI / "pending"
VALID_CLASSES = {"document", "sensitive-boundary", "generated-or-vendored", "internal-metadata"}
REQUIRED_PAGE_FIELDS = {"title", "source_files", "last_reviewed"}
REQUIRED_PENDING_FIELDS = {"status", "base", "head", "paths", "question", "owner", "created"}


class ValidationError(Exception):
    pass


def fail(message: str) -> None:
    raise ValidationError(message)


def git(*args: str) -> str:
    result = subprocess.run(["git", *args], cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        fail(f"git {' '.join(args)} failed: {result.stderr.strip() or 'unknown error'}")
    return result.stdout


def tracked_files() -> set[str]:
    return set(filter(None, git("ls-files").splitlines()))


def parse_value(value: str) -> Any:
    value = value.strip()
    if value.startswith("["):
        try:
            return json.loads(value)
        except json.JSONDecodeError as error:
            fail(f"invalid inline list: {error.msg}")
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        return value[1:-1]
    return value


def front_matter(path: Path) -> tuple[dict[str, Any], str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail(f"{path.relative_to(ROOT)}: missing YAML front matter")
    end = text.find("\n---\n", 4)
    if end < 0:
        fail(f"{path.relative_to(ROOT)}: unterminated YAML front matter")
    metadata: dict[str, Any] = {}
    active_list: str | None = None
    for line in text[4:end].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - "):
            if active_list is None:
                fail(f"{path.relative_to(ROOT)}: list item without a key")
            metadata.setdefault(active_list, []).append(parse_value(line[4:]))
            continue
        if ":" not in line:
            fail(f"{path.relative_to(ROOT)}: invalid front matter line: {line}")
        key, value = line.split(":", 1)
        key = key.strip()
        if not key or key in metadata:
            fail(f"{path.relative_to(ROOT)}: invalid or duplicate front matter key: {key}")
        value = value.strip()
        if value:
            metadata[key] = parse_value(value)
            active_list = None
        else:
            metadata[key] = []
            active_list = key
    return metadata, text[end + 5 :]


def load_rules() -> list[dict[str, Any]]:
    try:
        data = json.loads(MAP_FILE.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"missing {MAP_FILE.relative_to(ROOT)}")
    except json.JSONDecodeError as error:
        fail(f"{MAP_FILE.relative_to(ROOT)}: invalid JSON-compatible YAML: {error.msg}")
    rules = data.get("rules") if isinstance(data, dict) else None
    if not isinstance(rules, list):
        fail("source map must contain a rules list")
    for index, rule in enumerate(rules, 1):
        if not isinstance(rule, dict):
            fail(f"source-map rule {index}: must be an object")
        if not isinstance(rule.get("path"), str) or not rule["path"]:
            fail(f"source-map rule {index}: path is required")
        if rule.get("classification") not in VALID_CLASSES:
            fail(f"source-map rule {index}: invalid classification")
        if not isinstance(rule.get("rationale"), str) or not rule["rationale"]:
            fail(f"source-map rule {index}: public-safe rationale is required")
        pages = rule.get("pages", [])
        if not isinstance(pages, list) or not all(isinstance(page, str) for page in pages):
            fail(f"source-map rule {index}: pages must be a list of paths")
        if rule["classification"] in {"document", "sensitive-boundary"} and not pages:
            fail(f"source-map rule {index}: documentation rules require pages")
    return rules


def matching_rules(path: str, rules: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [rule for rule in rules if fnmatch.fnmatchcase(path, rule["path"])]


def wiki_pages() -> list[Path]:
    return sorted(path for path in WIKI.glob("*.md") if path.name != "README.md")


def local_links(body: str) -> list[str]:
    links = re.findall(r"(?<!!)\[[^]]*\]\(([^)]+)\)", body)
    return [link.split()[0].strip("<>") for link in links if not re.match(r"(?:https?:|mailto:|#)", link)]


def validate_page(path: Path, tracked: set[str]) -> None:
    metadata, body = front_matter(path)
    missing = REQUIRED_PAGE_FIELDS - metadata.keys()
    if missing:
        fail(f"{path.relative_to(ROOT)}: missing fields: {', '.join(sorted(missing))}")
    if not isinstance(metadata["title"], str) or not metadata["title"]:
        fail(f"{path.relative_to(ROOT)}: title must be non-empty")
    if not isinstance(metadata["source_files"], list) or not metadata["source_files"]:
        fail(f"{path.relative_to(ROOT)}: source_files must be a non-empty list")
    try:
        dt.date.fromisoformat(str(metadata["last_reviewed"]))
    except ValueError:
        fail(f"{path.relative_to(ROOT)}: last_reviewed must be YYYY-MM-DD")
    if not re.search(r"^#\s+", body, re.MULTILINE):
        fail(f"{path.relative_to(ROOT)}: missing Markdown title")
    for source in metadata["source_files"]:
        if source not in tracked:
            fail(f"{path.relative_to(ROOT)}: source file is not tracked: {source}")
    for link in local_links(body):
        link_path = link.split("#", 1)[0]
        if link_path and not (path.parent / link_path).resolve().exists():
            fail(f"{path.relative_to(ROOT)}: broken local link: {link}")
    # Public wiki prose must not include absolute home paths, credentials, or raw tokens.
    prohibited = [r"/(?:home|Users)/[^\s`]+", r"(?i)(?:api[_-]?key|password|token)\s*[:=]\s*[^<\s][^\s]*"]
    for pattern in prohibited:
        if re.search(pattern, body):
            fail(f"{path.relative_to(ROOT)}: prohibited sensitive or machine-local reference")


def validate_pending(path: Path, tracked: set[str], rules: list[dict[str, Any]]) -> None:
    metadata, body = front_matter(path)
    missing = REQUIRED_PENDING_FIELDS - metadata.keys()
    if missing:
        fail(f"{path.relative_to(ROOT)}: missing fields: {', '.join(sorted(missing))}")
    if metadata["status"] not in {"open", "resolved"}:
        fail(f"{path.relative_to(ROOT)}: status must be open or resolved")
    for sha_field in ("base", "head"):
        if not re.fullmatch(r"[0-9a-f]{40}", str(metadata[sha_field])):
            fail(f"{path.relative_to(ROOT)}: {sha_field} must be a 40-character lowercase SHA")
    if not isinstance(metadata["paths"], list) or not metadata["paths"]:
        fail(f"{path.relative_to(ROOT)}: paths must be a non-empty list")
    try:
        created = dt.date.fromisoformat(str(metadata["created"]))
    except ValueError:
        fail(f"{path.relative_to(ROOT)}: created must be YYYY-MM-DD")
    for source in metadata["paths"]:
        if source not in tracked or len(matching_rules(source, rules)) != 1:
            fail(f"{path.relative_to(ROOT)}: path is not a live, uniquely mapped tracked file: {source}")
    if metadata["status"] == "open" and (dt.date.today() - created).days > 30:
        fail(f"{path.relative_to(ROOT)}: open pending record is older than 30 days")
    if re.search(r"/(?:home|Users)/[^\s`]+", body) or re.search(r"(?i)(?:password|token)\s*[:=]", body):
        fail(f"{path.relative_to(ROOT)}: pending record contains unsafe content")


def audit() -> None:
    tracked = tracked_files()
    rules = load_rules()
    for source in sorted(tracked):
        matches = matching_rules(source, rules)
        if len(matches) != 1:
            fail(f"source-map coverage: {source} matches {len(matches)} rules (expected 1)")
    for page in wiki_pages():
        validate_page(page, tracked)
    for pending in sorted(PENDING.glob("*.md")):
        if pending.name != "README.md":
            validate_pending(pending, tracked, rules)
    print("wiki audit passed")


def changed_files(base: str, head: str) -> set[str]:
    git("rev-parse", "--verify", f"{base}^{{commit}}")
    git("rev-parse", "--verify", f"{head}^{{commit}}")
    return set(filter(None, git("diff", "--name-only", "--diff-filter=ACMR", f"{base}...{head}").splitlines()))


def pending_covers(path: str, base: str, head: str, tracked: set[str], rules: list[dict[str, Any]]) -> bool:
    for record in PENDING.glob("*.md"):
        if record.name == "README.md":
            continue
        try:
            metadata, _ = front_matter(record)
            validate_pending(record, tracked, rules)
        except ValidationError:
            continue
        if metadata["status"] == "open" and metadata["base"] == base and metadata["head"] == head and path in metadata["paths"]:
            return True
    return False


def check(base: str, head: str) -> None:
    tracked = tracked_files()
    rules = load_rules()
    changed = changed_files(base, head)
    for source in sorted(changed & tracked):
        matches = matching_rules(source, rules)
        if len(matches) != 1:
            fail(f"change impact: {source} matches {len(matches)} rules (expected 1)")
        rule = matches[0]
        classification = rule["classification"]
        if classification in {"internal-metadata", "generated-or-vendored"}:
            continue
        owned_pages = set(rule.get("pages", []))
        if not (changed & owned_pages) and not pending_covers(source, base, head, tracked, rules):
            fail(f"change impact: {source} requires an update to {', '.join(sorted(owned_pages))} or an open pending record")
    print("wiki check passed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("audit")
    check_parser = commands.add_parser("check")
    check_parser.add_argument("--base", required=True)
    check_parser.add_argument("--head", required=True)
    args = parser.parse_args()
    try:
        if args.command == "audit":
            audit()
        else:
            check(args.base, args.head)
    except ValidationError as error:
        print(f"wiki check failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
