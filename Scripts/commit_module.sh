#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: ./Scripts/commit_module.sh \"feat(scope): message\""
  exit 1
fi

msg="$1"

git add -A
if git diff --cached --quiet; then
  echo "No staged changes to commit"
  exit 0
fi

git commit -m "$msg"

git push origin "$(git branch --show-current)"
