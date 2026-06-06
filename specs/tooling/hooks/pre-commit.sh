#!/bin/sh
# Pre-commit hook: auto-create drift-check sentinel when the open-org-spec
# submodule pointer is staged for commit.
# Installed by /adhere-to tooling — do not edit manually.
# Template source: open-org-spec/specs/tooling/hooks/pre-commit.sh
# Variables substituted at install time:
#   {{submodule_path}}  — path to the open-org-spec submodule (e.g. open-org-spec)
#   {{manifest_dir}}    — adoption manifest directory (e.g. .open-org-spec)

SUBMODULE_PATH="{{submodule_path}}"
MANIFEST_DIR="{{manifest_dir}}"
SENTINEL="${MANIFEST_DIR}/drift-check-pending"

# Only act when the submodule pointer is staged
if git diff --cached --name-only | grep -q "^${SUBMODULE_PATH}$"; then
  # Get old SHA (from HEAD; empty on first-ever commit)
  OLD_SHA=$(git rev-parse HEAD:"${SUBMODULE_PATH}" 2>/dev/null || echo "")

  # Get new SHA (from index)
  NEW_SHA=$(git diff --cached -- "${SUBMODULE_PATH}" | grep "^+Subproject" | awk '{print $3}')

  # Resolve to tags (fall back to short SHA if no exact tag)
  if [ -n "$OLD_SHA" ]; then
    OLD_TAG=$(git -C "${SUBMODULE_PATH}" describe --tags --exact-match "${OLD_SHA}" 2>/dev/null || echo "${OLD_SHA:0:7}")
  else
    OLD_TAG="initial"
  fi
  NEW_TAG=$(git -C "${SUBMODULE_PATH}" describe --tags --exact-match "${NEW_SHA}" 2>/dev/null || echo "${NEW_SHA:0:7}")

  # Write sentinel (gitignored — local only)
  printf 'from: %s\nto: %s\nbumped_at: %s\n' \
    "${OLD_TAG}" "${NEW_TAG}" "$(date -u +%Y-%m-%dT%H:%MZ)" > "${SENTINEL}"

  echo "open-org-spec bumped ${OLD_TAG} → ${NEW_TAG}. Drift check sentinel created."
  echo "Run /adhere-to tooling before pushing."
fi

exit 0
