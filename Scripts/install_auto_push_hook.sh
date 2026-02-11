#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_PATH="$ROOT_DIR/.git/hooks/post-commit"

cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

branch=$(git branch --show-current)
if [[ -z "$branch" ]]; then
  exit 0
fi

git push origin "$branch"
HOOK

chmod +x "$HOOK_PATH"
echo "Installed auto-push hook at $HOOK_PATH"
