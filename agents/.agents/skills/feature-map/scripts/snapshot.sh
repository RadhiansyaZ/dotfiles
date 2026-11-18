#!/usr/bin/env bash
# Extract a read-only snapshot of a git ref, so readers see a fixed baseline regardless of the working tree.
# Usage: snapshot.sh <repo-dir> <ref> <dest-parent>
# Result: <dest-parent>/<repo-name>/ plus one line "name ref sha date" on stdout.
# Does not touch the repo's working tree, index or branches.
set -euo pipefail
repo=$1 ref=$2 parent=$3
name=$(basename "$(cd "$repo" && pwd)")
sha=$(git -C "$repo" rev-parse --verify --short "$ref^{commit}")
date=$(git -C "$repo" log -1 --format=%ci "$ref")
dest="$parent/$name"
rm -rf "$dest" && mkdir -p "$dest"
git -C "$repo" archive "$ref" | tar -x -C "$dest"
echo "$name $ref $sha $date"
# Tell the coordinator whether the working tree differs from the snapshot in source (not docs) files.
changed=$(git -C "$repo" diff --name-only "$ref" -- . ':(exclude)*.md' 2>/dev/null | wc -l)
echo "  working tree vs $ref: $changed non-markdown paths differ (matters only for runtime checks)"
