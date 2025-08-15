# Azure RBAC Export Runbook

## Overview

This runbook provides step-by-step instructions for exporting Azure Role-Based Access Control (RBAC) data including role definitions and assignments across Management Groups, Subscriptions, and Resource Groups.

The export scripts support:
- **Role Definitions**: Built-in and custom roles
- **Role Assignments**: At all scope levels with inherited flag detection
- **Principal Resolution**: Best-effort name/UPN resolution with ID fallback
- **Large Tenant Safety**: Thresholds and confirmation for enterprise-scale environments
- **Multiple Output Formats**: CSV, XLSX, Markdown, and JSON

## Prerequisites

### Authentication
**Option 1: Okta SSO → Azure CLI**
```bash
# Corporate Okta sign-in (SSO flow)
az login
# Follow browser prompts for Okta → Entra ID authentication
```

**Option 2: Okta SSO → PowerShell**
```powershell
# Corporate Okta sign-in
Connect-AzAccount
# Follow browser prompts for Okta → Entra ID authentication
```

### Required Tools

**PowerShell Script:**
- PowerShell 7.3+
- Az.Accounts module (2.10.0+)
- Az.Resources module (6.0.0+)
- Optional: ImportExcel module for XLSX output

**Python Script:**
- Python 3.11+
- Required packages (install with `pip install -r requirements.txt`):
  - azure-identity
  - azure-mgmt-authorization
  - azure-mgmt-resource
  - azure-mgmt-managementgroups
  - Optional: openpyxl (for XLSX), msgraph-sdk (for principal resolution)

## Quick Start Examples

### PowerShell Examples

**Export specific subscriptions with redaction:**
```powershell
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -Subscriptions "sub1,sub2" -Redact
```

**Discover subscriptions with large tenant confirmation:**
```powershell
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -DiscoverSubscriptions -ConfirmLargeScan
```

**Traverse management groups without principal resolution (faster):**
```powershell
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -TraverseManagementGroups -NoResolvePrincipals
```

### Python Examples

**Export specific subscriptions with redaction:**
```bash
python scripts/azure/python/export_rbac_roles_and_assignments.py --subscriptions sub1,sub2 --redact
```

**Discover subscriptions with large tenant confirmation:**
```bash
python scripts/azure/python/export_rbac_roles_and_assignments.py --discover-subscriptions --confirm-large-scan
```

**Include resource-level assignments:**
```bash
python scripts/azure/python/export_rbac_roles_and_assignments.py --subscriptions sub1 --include-resources --limit 5
```

## Large Tenant Safety

⚠️ **READ THIS FIRST IF YOU HAVE >25 SUBSCRIPTIONS OR >200 RESOURCE GROUPS**

### Safety Rails Triggered When:
- More than 25 subscriptions targeted
- More than 200 resource groups across selected subscriptions
- `--include-resources` is set without `--subscriptions`

### Required Action:
Add `--confirm-large-scan` / `-ConfirmLargeScan` to proceed.

**Example for large tenant:**
```bash
python scripts/azure/python/export_rbac_roles_and_assignments.py --discover-subscriptions --confirm-large-scan
```

```powershell
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -DiscoverSubscriptions -ConfirmLargeScan
```

## Output Locations

### Default Structure
```
./output/azure/export_rbac_roles_and_assignments_{YYYYMMDD_HHMMSS}/
├── role_definitions.csv
├── role_assignments.csv
├── role_assignments.xlsx          # if ImportExcel/openpyxl available
├── role_assignments.md            # if --markdown-top > 0
├── role_assignments_{SUBID}.csv   # per-subscription files
├── role_assignments_{SUBID}.xlsx  # per-subscription XLSX
└── index.json                     # artifact inventory and row counts
```

### Logs
```
./logs/{YYYYMMDD}/
├── azure_export_rbac_roles_and_assignments_{runId}.log      # human-readable
├── azure_export_rbac_roles_and_assignments_{runId}.jsonl    # structured JSON
└── azure_export_rbac_roles_and_assignments_{runId}_summary.json
```

## Key Parameters

| Capability | Python Flag | PowerShell Param | Notes |
|------------|-------------|------------------|-------|
| Target subs | `--subscriptions SUB1,SUB2` | `-Subscriptions SUB1,SUB2` | CSV string or repeatable list |
| Include resources | `--include-resources` | `-IncludeResources` | Off by default |
| Expand groups | `--expand-group-members` | `-ExpandGroupMembers` | Extreme fan-out |
| Redact identities | `--redact` | `-Redact` | Masks UPNs/AppIds |
| Markdown rows | `--markdown-top N` | `-MarkdownTop N` | Default 200 |
| No resolution | `--no-resolve-principals` | `-NoResolvePrincipals` | Speeds up large runs |
| Confirm large | `--confirm-large-scan` | `-ConfirmLargeScan` | Required thresholds |
| Output path | `--output-path PATH` | `-OutputPath PATH` | Default deterministic |
| Safe mode | `--safe-mode` | `-SafeMode` | Default true |
| Max concurrency | `--max-concurrency 4` | `-MaxConcurrency 4` | Default 4 |
| Smoke test | `--limit N` | `-Limit N` | First N scopes |

## Discovery Parameters

| Feature | Python | PowerShell | Purpose |
|---------|--------|------------|---------|
| Subscription discovery | `--discover-subscriptions` | `-DiscoverSubscriptions` | Auto-find accessible subs |
| MG traversal | `--traverse-management-groups` | `-TraverseManagementGroups` | Enumerate MG scope |
| **Safety** | **Both OFF by default** | **Both OFF by default** | **Prevents auto-sweep** |

## Group Expansion Parameters

| Feature | Python | PowerShell | Notes |
|---------|--------|------------|-------|
| Member cap | `--group-members-top N` | `-GroupMembersTop N` | Default 500 |
| Mode | `--group-membership-mode direct\|transitive` | N/A | Transitive requires `--confirm-large-scan` |

## Output Ergonomics

### Per-Subscription Partitioning
Large tenants generate per-subscription CSV/XLSX files to prevent single massive files that Confluence struggles with.

### Markdown Export
Limited to `--markdown-top N` rows (default 200) to keep paste size manageable for documentation.

### CSV Encoding
Files are written with UTF-8 BOM for clean Excel on Windows compatibility.

## Exit Codes

- **0**: Success - All data exported without errors
- **1**: Failure - Critical errors prevented completion
- **2**: Partial - Completed with warnings or skipped scopes

Check the summary JSON for detailed results.

## Troubleshooting

See `docs/runbooks/common-troubleshooting.md` for:
- Authentication issues
- Module installation
- Permission gaps
- Throttling and retries
- Large tenant performance

## Confluence Integration

See `docs/runbooks/how-to-copy-into-confluence.md` for:
- CSV → table conversion tips
- When to use Markdown vs CSV
- Best practices for sharing RBAC data

---
*This runbook is part of the Cloud IAM Best Practice repository. Last updated: 2025*
