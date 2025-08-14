## 0. Purpose & Non-Goals

* **Purpose:** Define strict guardrails so Cline produces secure, auditable, enterprise-ready IAM scripting for Azure/Entra, AWS, and GCP—without embedding secrets or relying on interactive hacks.
* **Non-Goals:** Building any authentication bypasses, storing long-lived credentials, or writing platform-specific code that breaks portability.

## 1. Repository Layout (authoritative)

```text
/ (repo root)
├─ .editorconfig
├─ .gitignore
├─ README.md
├─ CONTRIBUTING.md
├─ CHANGELOG.md
├─ LICENSE (MIT by default unless overridden)
├─ docs/
│  ├─ runbooks/
│  │  ├─ azure-export-rbac.md
│  │  ├─ common-troubleshooting.md
│  │  └─ how-to-copy-into-confluence.md
│  └─ design/
│     └─ logging-schema.md
├─ common/
│  ├─ python/
│  │  └─ logging_utils.py
│  └─ powershell/
│     └─ Common.Logging.psm1
├─ azure/
│  ├─ python/
│  │  ├─ requirements.txt
│  │  ├─ constraints.txt
│  │  └─ export_rbac_roles_and_assignments.py
│  └─ powershell/
│     └─ Export-RbacRolesAndAssignments.ps1
├─ aws/           # placeholders only (today)
│  ├─ python/.keep
│  └─ powershell/.keep
└─ gcp/           # placeholders only (today)
   ├─ python/.keep
   └─ powershell/.keep
```

## 2. Security Posture (hard requirements)

* **No secrets in code or repo.** Never write credentials, client secrets, tokens, or tenant IDs into files. Use environment variables or interactive SSO only.
* **Federation only.** Human auth flows must rely on enterprise SSO (Okta/Ping/etc.). Do not implement “headless MFA workarounds.” For Azure, assume `az login` (device code or broker) is performed by the operator before running scripts.
* **Read-only by default.** All scripts must be **non-destructive** and **read-only** unless explicitly named `*-write` and reviewed later.
* **Principle of Least Privilege.** Query only the scopes and APIs necessary for inventory/reporting.
* **Sanitize outputs.** Never export secrets or PII. Role assignment exports may include principal names/UPNs; provide a `--redact` flag to hash/mask.

## 3. Cross-Cutting Behaviors (all scripts)

* **Config:** Support `--config path.yml` (optional) and environment variables; CLI args override config/env.
* **Preflight checks:** Validate CLI/SDK presence, sign-in state, and network reachability; print actionable messages.
* **Safe mode:** Default `--safe-mode` enforces read-only and disables any write paths (even if present later).
* **Deterministic outputs:** Write to `./output/{tool}/{name}_{YYYYMMDD_HHMMSS}/`.
* **Structured logging:**

  * Log file: `./logs/{YYYYMMDD}/{script}_{runId}.log` (human text).
  * JSON-Lines file: `./logs/{YYYYMMDD}/{script}_{runId}.jsonl` (machine).
  * Summary: `./logs/{YYYYMMDD}/{script}_{runId}_summary.json`.
* **Exit codes:** `0` success; `2` partial (warnings); `1` failure. Summaries must include counts.

## 4. Standard Log Envelope (JSON-Lines)

Every log event must include:

```json
{
  "ts": "2025-08-14T19:15:03.123Z",
  "run_id": "uuid-v4",
  "script": "azure/export_rbac_roles_and_assignments",
  "level": "INFO|WARN|ERROR",
  "event": "message short name",
  "detail": { "freeform": "structured context" }
}
```

## 5. Output Schemas (tabular exports)

All table exports (CSV/XLSX/MD table) must include:

**RBAC Role Definitions**

* `roleDefinitionName`, `roleDefinitionId`, `isCustom`, `description`, `permissionsCount`, `assignableScopes` (semicolon-delimited)

**RBAC Role Assignments (Scoped)**

* `scope`, `scopeType` (ManagementGroup|Subscription|ResourceGroup|Resource), `subscriptionId`, `resourceGroup`,
* `roleDefinitionId`, `roleDefinitionName`,
* `assignmentId`, `principalId`, `principalType` (User|Group|ServicePrincipal|ManagedIdentity), `principalDisplayName`, `principalUPNOrAppId`,
* `inherited` (true/false), `condition`, `conditionVersion`, `createdOn` (if available)

Optional: `groupMemberCount`, `expandedMember` (true/false). If `--expand-group-members` is set, add child rows with `memberPrincipalId`, `memberType`, `memberDisplayName`, `memberUPN`.

## 6. PowerShell Standards

* **Modules:** `Az.Accounts`, `Az.Resources`. Use `Connect-AzAccount` outside script or as an optional `-Login` switch that calls `Connect-AzAccount -UseDeviceAuthentication` if not signed in.
* **Style:** PSScriptAnalyzer clean; `Set-StrictMode -Version Latest`; `$ErrorActionPreference = 'Stop'`.
* **Comments & help:** Comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES` (prereqs, permissions, tested versions).
* **Output:** Use `Export-Csv -NoTypeInformation -Encoding UTF8` and (if available) `ImportExcel` for `.xlsx`, but **must** always produce CSV as the baseline.
* **Resilience:** Handle throttling & pagination; use `-ErrorAction Stop` and try/catch with rich context.

## 7. Python Standards

* **Runtime:** Python 3.11+.
* **Packaging:** `requirements.txt` + `constraints.txt` pinning exact versions.
* **Lint/format:** `black`, `ruff` (or `flake8`), `mypy` (loose), `isort`.
* **SDKs:** Prefer Azure SDKs (`azure-identity`, `azure-mgmt-authorization`, `azure-mgmt-resource`, `azure-mgmt-managementgroups`) and Microsoft Graph (`msgraph-sdk`) for principal resolution when needed. Fallback to Azure CLI via subprocess for gaps—but keep this optional.
* **Auth:** `DefaultAzureCredential()` first; support `AzureCliCredential()` if CLI context exists. No embedded app registrations.
* **I/O:** Use `csv` and `openpyxl` (optional) for XLSX. Always produce CSV.
* **Logging:** `logging` with JSON handler; capture stack traces on ERROR; write summary JSON.

## 8. Azure/Entra RBAC Enumeration Rules

* Enumerate **role definitions** (built-in + custom) visible to the signed-in context.
* Enumerate **role assignments** at **all scopes**:

  1. Management Groups
  2. Subscriptions
  3. Resource Groups (and optionally Resource level)
* Include inherited assignments; mark with `inherited=true`.
* Resolve principals to **display name** and **UPN/AppId** via Graph when feasible; otherwise return IDs.
* Offer flags: `--subscriptions <csv>`, `--exclude-mg`, `--include-resources`, `--expand-group-members`, `--redact`, `--markdown`.

## 9. Error Handling & Validation

* On failure, write: the failing scope, API, token audience, and recommended operator action.
* Summaries **must** report: `scopes_processed`, `roles_count`, `assignments_count`, `warnings`, `errors`, `duration_seconds`, `success=true|false`.

## 10. Documentation Deliverables (mandatory)

* `docs/runbooks/azure-export-rbac.md` — step-by-step, screenshots placeholders, copy-ready to Confluence.
* `docs/runbooks/common-troubleshooting.md` — common auth and RBAC listing issues.
* `docs/how-to-copy-into-confluence.md` — guidance for CSV → table, and optional MD table export.

## 11. Version Control & CI

* **Conventional Commits**; require meaningful scope, e.g., `feat(azure): add CSV export`.
* Keep CHANGELOG with `Keep a Changelog` format; semantic version tags.
* Add GitHub Actions (optional later) to run linting and PSScriptAnalyzer/mypy on PRs.

## 12. Acceptance Checklist (Cline must satisfy)

* [ ] Repo tree exactly as in §1.
* [ ] Both **PowerShell** and **Python** Azure RBAC exporters present.
* [ ] Logging libs present in `common/` for both languages and used by scripts.
* [ ] CSV export always produced; XLSX optional. MD table optional via flag.
* [ ] Preflight checks & safe mode present.
* [ ] Runbook(s) thorough, non-technical friendly, grammar-perfect.
* [ ] No secrets or hardcoded tenant IDs.
* [ ] Scripts succeed with `az login` pre-performed; clear errors otherwise.
* [ ] Summary JSON written and exit code honors outcome.
* [ ] Linting/formatting passes (ruff/black/mypy; PSScriptAnalyzer).

---

# Cline – Implementation Brief (copy this whole block)

**Role:** You are an engineer implementing secure, auditable, enterprise-grade IAM reporting scripts for a large bank. Follow `cline_rules.md` in this repo as a binding contract. Today you will implement Azure/Entra functionality, while scaffolding AWS/GCP directories for future work.

## Goals (for this pass)

1. Create the full repository scaffold (see “Repository Layout” below).

2. Implement **Azure/Entra RBAC export** in **PowerShell** and **Python**:

   * Pull **all Azure role definitions** (built-in & custom).
   * Pull **all role assignments** at **Management Group**, **Subscription**, and **Resource Group** scopes (include inherited).
   * Resolve principal display names/UPNs/AppIds where feasible.
   * Export results to **CSV** (always) and **XLSX** (optional if dependency available).
   * Provide optional **Markdown table** export for small subsets to paste into Confluence.
   * Implement modular **logging, error tracking, success/failure validation, and summary** (shared libs in `/common`).

3. Author docs: `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and step-by-step runbooks.

### Repository Layout (create exactly)

```
[see cline_rules.md §1; mirror that tree exactly]
```

### Common Libraries (must create & use)

* **PowerShell:** `/common/powershell/Common.Logging.psm1`

  * Functions: `New-RunId`, `Start-Run`, `Write-LogJson`, `Write-LogText`, `Write-Summary`, `New-OutputPaths`.
* **Python:** `/common/python/logging_utils.py`

  * Functions: `init_logging(script_name) -> (logger, run_id, paths)`, `write_summary(dict)`, `now_utc_iso()`.

### Azure/Entra Implementation Details

#### PowerShell script: `azure/powershell/Export-RbacRolesAndAssignments.ps1`

* **Prereqs:** `Az.Accounts`, `Az.Resources`; assume operator has already run `Connect-AzAccount`. Provide `-Login` switch to attempt device login if not signed in.
* **Capabilities:**

  * Enumerate management groups (`Get-AzManagementGroup`), subscriptions (`Get-AzSubscription`), and RGs.
  * Role definitions: `Get-AzRoleDefinition`.
  * Role assignments: `Get-AzRoleAssignment -IncludeClassicAdministrators:$false -IncludeInactivePrincipals:$true` respecting scope.
  * Mark `inherited` using assignment scope vs. evaluated scope comparison.
  * Resolve principal display name/UPN via `Get-AzADUser`, `Get-AzADGroup`, `Get-AzADServicePrincipal` (best-effort). If Graph call fails, keep IDs.
  * CLI switches:
    `-Subscriptions <string[]>`, `-IncludeResources`, `-ExpandGroupMembers`, `-Redact`, `-Markdown`, `-OutputPath <path>`, `-SafeMode:$true`.
* **Outputs:** CSV mandatory; XLSX optional (use `ImportExcel` **only if module available**); summary JSON; logs (text + jsonl).

#### Python script: `azure/python/export_rbac_roles_and_assignments.py`

* **Prereqs:** `azure-identity`, `azure-mgmt-authorization`, `azure-mgmt-resource`, `azure-mgmt-managementgroups`, `msgraph-sdk` (optional best-effort for name resolution), `openpyxl` (optional).
* **Auth:** Try `DefaultAzureCredential` → fallback to `AzureCliCredential`. No client secrets.
* **Flow:**

  * Discover management groups and subscriptions visible to the principal.
  * Enumerate role definitions and role assignments per scope; compute `inherited`; resolve principal names via Graph if permitted.
  * Support flags: `--subscriptions`, `--include-resources`, `--expand-group-members`, `--redact`, `--markdown`, `--output-path`, `--safe-mode`.
* **Outputs:** Same columns and files as PowerShell; identical summary schema; identical exit codes.

### Output Schemas & Logs

* **Follow cline\_rules.md §4–§5 strictly.**
* Always create `./output/azure/export_rbac_roles_and_assignments_{timestamp}/` with:

  * `role_definitions.csv`
  * `role_assignments.csv`
  * `role_assignments.xlsx` (if available)
  * `role_assignments.md` (when `--markdown`/`-Markdown` set for small slices)
* Logs + summary under `./logs/...` with `run_id`.

### Documentation to write (grammar-perfect, plain Markdown)

* **README.md** — repo purpose, quickstart, structure, prerequisites (Az PowerShell, Azure CLI, Python 3.11), and examples:

  * PowerShell:

    ```pwsh
    # Sign in (device code or broker via Okta SSO)
    Connect-AzAccount
    ./azure/powershell/Export-RbacRolesAndAssignments.ps1 -Subscriptions "SUB1","SUB2"
    ```
  * Python:

    ```bash
    az login  # via Okta SSO in browser
    python -m venv .venv && source .venv/bin/activate
    pip install -r azure/python/requirements.txt -c azure/python/constraints.txt
    python azure/python/export_rbac_roles_and_assignments.py --subscriptions SUB1,SUB2
    ```
* **CONTRIBUTING.md** — coding standards (PSScriptAnalyzer, black/ruff/mypy), Conventional Commits, PR checklist (tests, lint, logs, summary).
* **CHANGELOG.md** — initialize with `v0.1.0` features added today.
* **docs/runbooks/azure-export-rbac.md** — non-technical, step-by-step with screenshots placeholders:

  1. Install prerequisites
  2. Sign in (`az login` or `Connect-AzAccount`)
  3. Run command (PowerShell or Python)
  4. Where to find outputs
  5. How to copy into Confluence (CSV → table; or MD table)
* **docs/runbooks/common-troubleshooting.md** — auth errors, missing module fixes, throttling, permissions.
* **docs/how-to-copy-into-confluence.md** — include tip to paste CSV as table; provide `--markdown` for small outputs.

### Dependencies & Pinning

* Create `azure/python/requirements.txt` including:

  ```
  azure-identity==1.17.1
  azure-mgmt-authorization==3.0.0
  azure-mgmt-resource==23.1.0
  azure-mgmt-managementgroups==1.0.0
  msgraph-sdk==1.14.0
  openpyxl==3.1.5
  ```
* Create `azure/python/constraints.txt` mirroring exact pins.

### Testing Plan (manual, since operator can’t return error codes)

* **Dry run:** If not signed in, scripts must exit with code `1`, printing: “No Azure session detected. Run `az login` or `Connect-AzAccount`.”
* **Happy path:** With a test subscription, verify CSVs exist and summary shows non-zero `roles_count` and `assignments_count`.
* **Large tenant safety:** Ensure `--subscriptions` limits scope; warn if more than 200 RGs are discovered without `--include-resources`.

### Acceptance Criteria (must pass)

* Folder structure exact.
* Both languages produce **identical column sets**.
* CSV output always present; XLSX optional; MD table optional.
* Logs (text + JSONL) + summary JSON written; exit codes correct.
* Runbooks are clear for non-technical users.
* No secrets, no tenant IDs hardcoded, no write operations.

### Nice-to-Have (if time remains)

* Markdown generator that chunks results per-subscription to keep tables manageable for Confluence.
* Simple `Makefile`/`Taskfile.yml` to run linting in one command.

**Begin now.** Adhere strictly to `cline_rules.md`. If any ambiguity exists, choose the more secure and conservative option, keep outputs deterministic, and document your choice in the README’s “Design Notes” section.