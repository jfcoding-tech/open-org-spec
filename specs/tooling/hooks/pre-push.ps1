# Pre-push hook (PowerShell companion): block pushes when open-org-spec drift check is pending.
# This script is the PowerShell equivalent of pre-push.sh for environments that invoke
# git hooks via PowerShell rather than bash.
# Installed by /adhere-to tooling alongside pre-push.sh — do not edit manually.
# Template source: open-org-spec/specs/tooling/hooks/pre-push.ps1
# Variables substituted at install time:
#   {{owner_email}}   — manifest owner's git email (config.yaml#owner.email)
#   {{manifest_dir}}  — adoption manifest directory (e.g. .open-org-spec)

$sentinel = "{{manifest_dir}}/drift-check-pending"
$ownerEmail = "{{owner_email}}"

# Read current git identity
$currentEmail = git config user.email 2>$null

# Only gate the manifest owner — all other contributors are unaffected
if ($currentEmail -eq $ownerEmail -and (Test-Path $sentinel) -and (Get-Item $sentinel).Length -gt 0) {
    Write-Host ""
    Write-Host "ERROR: open-org-spec drift check is pending."
    Write-Host "  Run /adhere-to tooling to check for drift and clear the sentinel before pushing."
    Write-Host "  Sentinel: $sentinel"
    Write-Host ""
    exit 1
}

exit 0
