#!/bin/sh
# Pre-push hook: block pushes when open-org-spec drift check is pending.
# Installed by /adhere-to tooling — do not edit manually.
# Template source: open-org-spec/specs/tooling/hooks/pre-push.sh
# Variables substituted at install time:
#   {{owner_email}}   — manifest owner's git email (config.yaml#owner.email)
#   {{manifest_dir}}  — adoption manifest directory (e.g. .open-org-spec)

SENTINEL="{{manifest_dir}}/drift-check-pending"
OWNER_EMAIL="{{owner_email}}"

# Read current git identity
CURRENT_EMAIL=$(git config user.email 2>/dev/null)

# Only gate the manifest owner — all other contributors are unaffected
if [ "$CURRENT_EMAIL" = "$OWNER_EMAIL" ] && [ -f "$SENTINEL" ] && [ -s "$SENTINEL" ]; then
  echo ""
  echo "ERROR: open-org-spec drift check is pending."
  echo "  Run /adhere-to tooling to check for drift and clear the sentinel before pushing."
  echo "  Sentinel: $SENTINEL"
  echo ""
  exit 1
fi

exit 0
