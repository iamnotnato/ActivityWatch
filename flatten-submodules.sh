#!/usr/bin/env bash
# flatten-submodules.sh
#
# Turns every git submodule (at any nesting depth) inside the current
# repository into plain, regularly-tracked files. After this runs, the repo
# has no .gitmodules, no gitlink (160000) entries, and no embedded .git
# folders anywhere below the top level - just one flat set of files that
# you own and can push anywhere.
#
# Usage: run from the ROOT of the already-cloned repo:
#   ./flatten-submodules.sh
set -euo pipefail

# Make sure a commit identity exists locally, otherwise the final commit
# below will fail with "Author identity unknown".
if ! git config user.email >/dev/null 2>&1; then
  git config user.email "you@example.com"
  git config user.name "Your Name"
  echo "==> No git identity configured; set a local placeholder (user.email/user.name)."
  echo "    Change it later with: git config user.name / user.email"
fi

echo "==> Making sure all submodules (recursively) are checked out..."
git submodule update --init --recursive

if [ ! -f .gitmodules ]; then
  echo "No .gitmodules found at the top level - nothing to flatten."
  exit 0
fi

echo "==> Recording top-level submodule paths..."
mapfile -t SUB_PATHS < <(git config -f .gitmodules --get-regexp path | awk '{print $2}')
printf '    %s\n' "${SUB_PATHS[@]}"

echo "==> Stripping every nested .git (submodule-of-submodule boundaries)..."
find . -mindepth 2 -name ".git" -print -exec rm -rf {} +

echo "==> Removing every nested .gitmodules file..."
find . -mindepth 2 -name ".gitmodules" -print -delete

echo "==> Dropping the top-level .gitmodules..."
git rm -f --quiet .gitmodules

echo "==> Re-adding each former submodule path as plain tracked files..."
for p in "${SUB_PATHS[@]}"; do
  echo "    flattening: $p"
  git rm -r --cached --quiet "$p"
  git add -f "$p"
done

echo "==> Clearing submodule storage/config..."
rm -rf .git/modules
# Remove any leftover [submodule "..."] blocks from the local config, ignore
# errors for ones that don't exist there.
for p in "${SUB_PATHS[@]}"; do
  git config --remove-section "submodule.$p" 2>/dev/null || true
done

echo "==> Staging everything and committing..."
git add -A
git commit -m "Flatten all submodules into regular tracked files"

echo "==> Verifying no gitlinks or submodule files remain..."
LEFTOVER_LINKS=$(git ls-files -s | grep '^160000' || true)
LEFTOVER_GITDIRS=$(find . -mindepth 2 -name ".git" || true)
LEFTOVER_GITMODULES=$(find . -name ".gitmodules" || true)

if [ -z "$LEFTOVER_LINKS" ] && [ -z "$LEFTOVER_GITDIRS" ] && [ -z "$LEFTOVER_GITMODULES" ]; then
  echo "==> SUCCESS: repository is fully flattened."
else
  echo "==> WARNING: some traces remain:"
  echo "$LEFTOVER_LINKS"
  echo "$LEFTOVER_GITDIRS"
  echo "$LEFTOVER_GITMODULES"
  exit 1
fi

echo "==> Optional cleanup (shrinks .git):"
echo "    git reflog expire --expire=now --all && git gc --prune=now --aggressive"
