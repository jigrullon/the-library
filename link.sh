#!/usr/bin/env bash
# Symlink every skill in this repo's skills/ dir into ~/.claude/skills/ so edits
# there are edits to the repo (single source of truth, no drift).
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
target="$HOME/.claude/skills"
mkdir -p "$target"
for dir in "$repo"/skills/*/; do
  name="$(basename "$dir")"
  dest="$target/$name"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "skip $name: $dest exists and is not a symlink"
    continue
  fi
  ln -sfn "$repo/skills/$name" "$dest"
  echo "linked $name"
done
