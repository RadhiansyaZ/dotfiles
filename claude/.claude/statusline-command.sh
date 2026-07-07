#!/bin/bash
# Claude Code statusline. Reads session JSON on stdin.
# Line 1: cwd (relative to $HOME) and git branch (truncated)
# Line 2: model name and context window remaining

# Max git branch length before truncation (leading chars kept, "…" suffix).
BRANCH_MAXLEN="${BRANCH_MAXLEN:-20}"

input="$(cat)"

# Prefer Claude's cwd from session JSON; fall back to .cwd, then $PWD.
dir="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
[ -z "$dir" ] && dir="$(pwd)"

# Show path relative to home, using ~ shorthand.
home="${HOME:-/home/$(whoami)}"
case "$dir" in
  "$home") dispdir="~" ;;
  "$home"/*) dispdir="~${dir#$home}" ;;
  *) dispdir="$dir" ;;
esac

# Git branch for $dir, if inside a work tree. Detached HEAD shows short SHA.
branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null \
  || git -C "$dir" rev-parse --short HEAD 2>/dev/null)"

# Truncate long branch names, keeping the leading part and appending "…".
if [ -n "$branch" ] && [ "${#branch}" -gt "$BRANCH_MAXLEN" ]; then
  branch="${branch:0:BRANCH_MAXLEN}…"
fi

model="$(printf '%s' "$input" | jq -r '.model.display_name // empty')"

# Context window remaining percentage, computed from available fields.
remaining="$(printf '%s' "$input" | jq -r '
  .context_window.remaining_percentage as $r
  | if $r != null then ($r | tostring)
    else
      (.context_window.used_percentage // empty) as $u
      | if $u != null then (100 - $u | tostring) else empty end
    end
  // empty
')"

if [ -z "$remaining" ]; then
  remaining="$(printf '%s' "$input" | jq -r '
    (.context_window.context_window_size // empty) as $size
    | (.context_window.total_input_tokens // empty) as $used
    | if ($size != null and $used != null and ($size|tonumber) > 0) then
        (100 - (($used|tonumber) * 100 / ($size|tonumber)) | floor | tostring)
      else empty end
  ')"
fi

printf '\033[01;34m%s\033[00m' "$dispdir"
[ -n "$branch" ] && printf ' \033[00;32m%s\033[00m' "$branch"
printf '\n'
[ -n "$model" ] && printf '\033[01;35m%s\033[00m' "$model"
if [ -n "$remaining" ]; then
  [ -n "$model" ] && printf ' \033[00;90m|\033[00m '
  printf '\033[00;90mContext: %s%% remaining\033[00m' "$remaining"
fi
