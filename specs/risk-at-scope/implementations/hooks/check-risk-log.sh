#!/usr/bin/env bash
# check-risk-log.sh — git pre-commit hook for risk record conformance
#
# Validates every staged risk record file against the risk-at-scope inline log
# contract (proposal: open-org-spec/proposals/risk-inline-log.md, section 6,
# Layer 2).
#
# For each staged file matching */risks/<slug>.md (excluding README.md):
#
#   1. Required frontmatter fields — id, title, description, owner, status, and
#      escalation_threshold must all be present and non-empty.
#   2. ## Log section present — the file body must contain a "## Log" heading.
#   3. Log entry matches disposition_at — if disposition_at is set, at least one
#      "### <disposition_at value> —" heading must exist inside ## Log.
#
# If any check fails the hook prints a labelled error per violation and exits
# non-zero, aborting the commit.
#
# Scope boundary: this hook validates risk record files only (*/risks/*.md).
# The risk catalogue (governance/catalogue/risks.yaml) is agent-generated on a
# separate automated stream and must NOT be checked by this hook.
#
# Reference implementation — adopters adapt the RISK_FILE_PATTERN and
# EXCLUDED_NAMES constants to match their repository's path conventions.

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────

# Pattern passed to grep -E to identify staged files that are risk records.
# Matches any file named *.md inside a directory called "risks/" at any depth.
# Adopters: adjust if your convention differs (e.g. risk-records/ instead of risks/).
RISK_FILE_PATTERN='(^|/)risks/[^/]+\.md$'

# Filenames to skip unconditionally (case-sensitive).
EXCLUDED_NAMES="README.md"

# Required frontmatter fields (POSIX grep -E patterns).
REQUIRED_FIELDS="id title description owner status escalation_threshold"

# ── Helpers ───────────────────────────────────────────────────────────────────

# Print a single failure line, indented for readability.
fail() {
  echo "  [FAIL] $1"
}

# Return 0 if $1 is a non-empty frontmatter field value for key $2 in file $3.
# Frontmatter is defined as content between the first pair of "---" lines.
frontmatter_value() {
  local key="$1" file="$2"
  # Extract the YAML block between the opening and closing --- fences, then
  # look for "key: <non-empty value>". awk stops after the closing fence.
  awk '
    /^---/ { fence++; next }
    fence == 1 { print }
    fence == 2 { exit }
  ' "$file" | grep -E "^${key}:[[:space:]]+\S" >/dev/null 2>&1
}

# ── Main ──────────────────────────────────────────────────────────────────────

# Collect staged files that look like risk records.
# git diff-index lists staged (cached) changes. We ask for added (A),
# copied (C), and modified (M) files — deleted files need no validation.
staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

if [ -z "$staged_files" ]; then
  exit 0
fi

# Filter to risk record paths only.
risk_files=$(echo "$staged_files" | grep -E "$RISK_FILE_PATTERN" || true)

if [ -z "$risk_files" ]; then
  # No risk records staged — nothing to check.
  exit 0
fi

overall_pass=0  # 0 = all good; set to 1 on first failure

while IFS= read -r filepath; do
  # Skip excluded filenames (e.g. README.md inside a risks/ folder).
  basename_=$(basename "$filepath")
  case "$EXCLUDED_NAMES" in
    *"$basename_"*) continue ;;
  esac

  # Read the staged version of the file (not the working-tree copy, which may
  # differ from what is actually being committed).
  file_content=$(git show ":$filepath" 2>/dev/null) || {
    echo "  [WARN] could not read staged content for $filepath — skipping"
    continue
  }

  file_failed=0
  header_printed=0

  # Print the per-file header on first failure only.
  print_header() {
    if [ "$header_printed" -eq 0 ]; then
      echo ""
      echo "RISK CONFORMANCE: $filepath"
      header_printed=1
    fi
  }

  # ── Check 1: required frontmatter fields ────────────────────────────────────
  # Extract the frontmatter block (content between the first two --- fences).
  frontmatter=$(echo "$file_content" | awk '
    /^---/ { fence++; next }
    fence == 1 { print }
    fence == 2 { exit }
  ')

  for field in $REQUIRED_FIELDS; do
    # A field is present and non-empty when "field: <something>" appears in
    # the frontmatter, where <something> is at least one non-whitespace char.
    if ! echo "$frontmatter" | grep -qE "^${field}:[[:space:]]+\S"; then
      print_header
      fail "missing required field: $field"
      file_failed=1
    fi
  done

  # ── Check 2: ## Log section present ─────────────────────────────────────────
  if ! echo "$file_content" | grep -qE "^## Log[[:space:]]*$"; then
    print_header
    fail "## Log section absent"
    file_failed=1
  fi

  # ── Check 3: log entry matches disposition_at ────────────────────────────────
  # Extract disposition_at from frontmatter (value after "disposition_at: ").
  disposition_at=$(echo "$frontmatter" | grep -E "^disposition_at:[[:space:]]+" | \
    sed 's/^disposition_at:[[:space:]]*//' | tr -d '[:space:]"' || true)

  if [ -n "$disposition_at" ]; then
    # Expect at least one heading of the form "### YYYY-MM-DD —" in the Log
    # section, where the date matches disposition_at exactly.
    # We match anywhere in the file (the heading format is globally unique by
    # convention) rather than trying to scope the search to the Log section
    # only — simpler and robust enough at this scale.
    if ! echo "$file_content" | grep -qE "^### ${disposition_at}[[:space:]]+—"; then
      print_header
      fail "disposition_at ${disposition_at} has no matching ## Log entry"
      file_failed=1
    fi
  fi

  if [ "$file_failed" -eq 1 ]; then
    overall_pass=1
  fi

done <<< "$risk_files"

if [ "$overall_pass" -ne 0 ]; then
  echo ""
  echo "Commit aborted. Fix the conformance errors above and re-run git commit."
  echo "Each risk record requires:"
  echo "  - frontmatter fields: id, title, description, owner, status, escalation_threshold"
  echo "  - a ## Log section"
  echo "  - a ### <disposition_at> — entry in ## Log when disposition_at is set"
  echo ""
  echo "See open-org-spec/specs/risk-at-scope/implementations/hooks/README.md"
  exit 1
fi

exit 0
