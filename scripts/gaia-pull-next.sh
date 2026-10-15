#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

REPO="${GAIA_REPO:-machackabook/Gaia-The-Nexus-Generation}"
BRANCH="${GAIA_BRANCH:-automation/gaia-autopilot-bootstrap}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v git >/dev/null || { echo 'git is required'; exit 127; }
command -v gh >/dev/null || { echo 'GitHub CLI (gh) is required'; exit 127; }

git -C "$ROOT" fetch origin "$BRANCH"
if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git -C "$ROOT" switch "$BRANCH"
else
  git -C "$ROOT" switch --track -c "$BRANCH" "origin/$BRANCH"
fi

git -C "$ROOT" pull --ff-only origin "$BRANCH"

bash "$ROOT/scripts/gaia-autopilot.sh" advance

git -C "$ROOT" add -A
if git -C "$ROOT" diff --cached --quiet; then
  echo '[GAIA-PULL-NEXT] no local changes'
else
  git -C "$ROOT" config user.name 'gaia-autopilot[bot]'
  git -C "$ROOT" config user.email 'gaia-autopilot[bot]@users.noreply.github.com'
  git -C "$ROOT" commit -m 'chore: catalog local environment and advance state'
  git -C "$ROOT" push origin "$BRANCH"
fi

echo '[GAIA-PULL-NEXT] next step is available in .gaia/state/next-step.md'
