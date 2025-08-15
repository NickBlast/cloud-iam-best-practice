# Implementation Brief — Azure RBAC Export Scripts

## Objective
Implement secure, read-only, SSO-aligned IAM reporting for Azure/Entra within this repo, following `.clinerules/rules.md` as a binding contract.

## Key Deliverables

### 1. Directory Structure & Placeholders
- Create `/scripts` tree with common logging libs and per-cloud/language scaffolding
- Azure fully implemented; AWS/GCP as placeholders

### 2. Azure RBAC Export Functionality
**PowerShell Script**: `/scripts/azure/powershell/Export-RbacRolesAndAssignments.ps1`
**Python Script**: `/scripts/azure/python/export_rbac_roles_and_assignments.py`

**Core Capabilities:**
- List role definitions (built-in + custom)
- List role assignments at Management Group, Subscription, and Resource Group scopes
- Mark inherited assignments
- Resolve principal names (best-effort) with fallback to IDs
- Support redaction of sensitive identifiers
- Export CSV (always), optional XLSX, optional Markdown
- Preflight checks, structured logging, and summary JSON with proper exit codes

### 3. Shared Logging Libraries
- **PowerShell**: `/scripts/common/powershell/Common.Logging.psm1`
- **Python**: `/scripts/common/python/logging_utils.py`

### 4. Documentation
- `docs/runbooks/azure-export-rbac.md` (non-technical step-by-step)
- `docs/runbooks/common-troubleshooting.md`
- `docs/runbooks/how-to-copy-into-confluence.md`
- `docs/design/logging-schema.md`
- Update `README.md` with Scripts quickstart section

### 5. Dependency Management
- `/scripts/azure/python/requirements.txt` and `constraints.txt` with explicit pins
- Python 3.11+ compatibility

## Security Requirements
- SSO-only authentication (no stored secrets)
- Read-only operations with safe mode enabled by default
- Least privilege scope control with subscription filtering
- Redaction option for UPNs/AppIds
- No PII/secret exfiltration

## Output Standards
- Deterministic output paths with timestamped directories
- Structured logging (text + JSONL + summary JSON)
- Exit codes: 0 (success), 1 (failure), 2 (partial/warnings)
- Consistent column schemas between PowerShell and Python

## Implementation Approach
1. Create directory structure and placeholder files
2. Implement shared logging libraries
3. Develop PowerShell RBAC exporter with full parameter support
4. Develop Python RBAC exporter with matching functionality
5. Create comprehensive documentation
6. Add repository hygiene files (.gitignore, .editorconfig, etc.)
7. Update README with quickstart section
