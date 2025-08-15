# Cline Rules — Cloud IAM Best Practice (Repo-Aware)

**Repo:** `NickBlast/cloud-iam-best-practice`  
**Intent:** Add an enterprise-grade scripts tree (Azure now; AWS/GCP placeholders), shared logging, deterministic exports, and runbooks — without disrupting existing research docs under `docs/`.

---

## 0) Scope & Non-Goals

- **In scope:** 
  - Create `/scripts` with `/azure`, `/aws`, `/gcp` subtrees, each split by language (`/powershell`, `/python`).
  - Implement **Azure/Entra RBAC export** (role **definitions** + **assignments** across **MG/Subscription/RG** scopes).
  - Add **non-technical runbooks** and **common logging** libraries.
  - Author repo meta files: `README`, `CONTRIBUTING`, `CHANGELOG` (augment, don't overwrite if present; append sections if needed).

- **Non-goals:** 
  - No write operations (policy/role changes).
  - No stored secrets. No bypasses of SSO/MFA. No headless auth hacks.
  - No destructive or tenant-wide enumeration without explicit operator scope flags.

---

## 1) Repository Layout (authoritative for code/docs you add)

```

/ (repo root)
├─ .clinerules/
│  ├─ rules.md                  # this file
│  └─ implementation-brief.md   # the prompt you execute for this pass
├─ docs/
│  ├─ runbooks/
│  │  ├─ azure-export-rbac.md
│  │  ├─ common-troubleshooting.md
│  │  └─ how-to-copy-into-confluence.md
│  └─ design/
│     └─ logging-schema.md
├─ scripts/
│  ├─ common/
│  │  ├─ python/logging\_utils.py
│  │  └─ powershell/Common.Logging.psm1
│  ├─ azure/
│  │  ├─ python/
│  │  │  ├─ requirements.txt
│  │  │  ├─ constraints.txt
│  │  │  └─ export\_rbac\_roles\_and\_assignments.py
│  │  └─ powershell/
│  │     └─ Export-RbacRolesAndAssignments.ps1
│  ├─ aws/
│  │  ├─ python/.keep
│  │  └─ powershell/.keep
│  └─ gcp/
│     ├─ python/.keep
│     └─ powershell/.keep
├─ README.md            # extend with "Scripts" quickstart section (do not remove existing research content)
├─ CONTRIBUTING.md
├─ CHANGELOG.md
├─ .gitignore
└─ .editorconfig

```

**Rules:**
- Do **not** relocate or delete existing files under `docs/`. Only add the new `runbooks/` and `design/` subfolders above.
- Keep names and relative paths exactly as shown.

---

## 2) Security Posture (hard requirements)

- **SSO only; no secrets:** Authentication happens via enterprise SSO (Okta → Entra; Ping → AWS; similar for GCP). No client secrets, no app registrations embedded, no token caching in repo.
- **Read-only by default:** All scripts are non-destructive. Provide a `--safe-mode` (Python) / `-SafeMode` (PowerShell) flag which is **true by default**.
- **Least privilege & scope control:** Support `--subscriptions`/`-Subscriptions` filters; clearly label when traversing management groups.
- **Redaction option:** `--redact` masks UPNs/AppIds in outputs for sharing.
- **No PII/secret exfil:** Outputs must never contain tokens, passwords, or refreshable artifacts.

---

## 3) Cross-Cutting Implementation

- **Preflight:** Verify toolchain (Az PowerShell, Azure CLI, Python 3.11+), sign-in state, and network. Fail fast with actionable messages.
- **Deterministic outputs:** 
  - Root: `./output/azure/export_rbac_roles_and_assignments_{YYYYMMDD_HHMMSS}/`
  - Files: `role_definitions.csv`, `role_assignments.csv`, optional `role_assignments.xlsx`, optional `role_assignments.md`
- **Structured logging:**
  - Human text log → `./logs/{YYYYMMDD}/{script}_{runId}.log`
  - Machine JSONL → `./logs/{YYYYMMDD}/{script}_{runId}.jsonl`
  - Summary JSON → `./logs/{YYYYMMDD}/{script}_{runId}_summary.json`
- **Exit codes:** `0` success, `2` partial (warnings), `1` failure.

**Log envelope (JSONL):**
```json
{"ts":"<ISO8601Z>","run_id":"<uuid>","script":"azure/export_rbac_roles_and_assignments","level":"INFO|WARN|ERROR","event":"<short>","detail":{...}}
```

---

## 4) Output Schemas (must match in PS & Py)

**Role Definitions**

* `roleDefinitionName`,`roleDefinitionId`,`isCustom`,`description`,`permissionsCount`,`assignableScopes`

**Role Assignments**

* `scope`,`scopeType`(ManagementGroup|Subscription|ResourceGroup|Resource),`subscriptionId`,`resourceGroup`,
* `roleDefinitionId`,`roleDefinitionName`,
* `assignmentId`,`principalId`,`principalType`(User|Group|ServicePrincipal|ManagedIdentity),`principalDisplayName`,`principalUPNOrAppId`,
* `inherited`(true|false),`condition`,`conditionVersion`,`createdOn`

**When `--expand-group-members` is used:** add `memberPrincipalId`,`memberType`,`memberDisplayName`,`memberUPN`.

---

## 5) PowerShell Standards

* **Modules:** `Az.Accounts`, `Az.Resources`. Assume operator already ran `Connect-AzAccount` (offer optional `-Login` to call `Connect-AzAccount -UseDeviceAuthentication` if needed).
* **Cmdlets used:**

  * Role assignments: `Get-AzRoleAssignment` (supports MG/sub/RG scope)
    Ref: [https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-powershell](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-powershell)
  * Role definitions: `Get-AzRoleDefinition`
    Ref: [https://learn.microsoft.com/powershell/module/az.resources/get-azroledefinition](https://learn.microsoft.com/powershell/module/az.resources/get-azroledefinition)
  * Management groups: `Get-AzManagementGroup`
    Ref: [https://learn.microsoft.com/powershell/module/az.resources/get-azmanagementgroup](https://learn.microsoft.com/powershell/module/az.resources/get-azmanagementgroup)
* **Quality bar:** `Set-StrictMode -Version Latest`, `$ErrorActionPreference='Stop'`, pass PSScriptAnalyzer.
* **Help & comments:** Use comment-based help with `.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE/.NOTES`.
* **Export:** Always CSV (UTF-8). If `ImportExcel` exists, also write `.xlsx`.

---

## 6) Python Standards

* **Runtime & tooling:** Python 3.11+, `black`, `ruff`, `isort`, `mypy` (loose).
* **SDKs:** `azure-identity`, `azure-mgmt-authorization`, `azure-mgmt-resource`, `azure-mgmt-managementgroups`; optionally `msgraph-sdk` for principal resolution; optionally `openpyxl` for XLSX.
* **Auth chain:** `DefaultAzureCredential()` → fallback `AzureCliCredential()` if CLI context present. No app secrets.
* **Exports:** Always CSV; XLSX optional. Optional Markdown for small tables to paste to Confluence.
* **Logging:** `logging` + JSON handler; write summary JSON with counts & duration.

---

## 7) Azure/Entra RBAC Enumeration Rules

* Enumerate **role definitions** (built-in + custom) visible to the signed-in principal.
  Ref: [https://learn.microsoft.com/azure/role-based-access-control/role-definitions-list](https://learn.microsoft.com/azure/role-based-access-control/role-definitions-list)
* Enumerate **role assignments** at **MG**, **Subscription**, and **Resource Group** scopes; include **inherited** where applicable.
  Ref (CLI/PS patterns):

  * [https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-powershell](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-powershell)
  * [https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-cli](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-cli)
* Principal resolution: try Graph best-effort for display name + UPN/AppId; if not permitted, keep IDs.
* Flags: `--subscriptions`, `--include-resources`, `--expand-group-members`, `--redact`, `--markdown`, `--output-path`, `--safe-mode`.

---

## 8) Documentation Deliverables (Markdown only)

* `docs/runbooks/azure-export-rbac.md` — step-by-step (non-technical), SSO sign-in notes, screenshots placeholders, outputs map.
* `docs/runbooks/common-troubleshooting.md` — auth issues, throttling, module install, permission gaps.
* `docs/runbooks/how-to-copy-into-confluence.md` — CSV → table and Markdown paste tips.
* `docs/design/logging-schema.md` — JSONL & summary JSON definitions + examples.

---

## 9) Version Control & CI

* **Conventional Commits**, `Keep a Changelog` format.
* Add lint tasks (PowerShell & Python) as future CI (placeholder note in `CONTRIBUTING.md`).

---

## 10) Acceptance Checklist

* [ ] Layout under `/scripts` exactly as in §1; **do not** alter existing research docs beyond adding runbooks.
* [ ] Azure RBAC exporters exist in **both** PowerShell & Python with **matching columns**.
* [ ] Shared logging libs in `/scripts/common/*` are used by both implementations.
* [ ] CSV always produced; XLSX & Markdown are optional flags.
* [ ] Preflight checks, deterministic output paths, redaction option, and summary JSON present.
* [ ] No secrets, no tenant IDs hardcoded, no write operations.
* [ ] Runbooks are clear, grammar-perfect, and copy-ready for Confluence.

---

## 11) Design Notes & References

* RBAC best practices & scope traversal patterns are aligned with Microsoft Learn's guidance for listing role **assignments** and **definitions**.

  * PS list assignments: [https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-powershell](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-powershell)
  * CLI list assignments: [https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-cli](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-list-cli)
  * List role definitions: [https://learn.microsoft.com/azure/role-based-access-control/role-definitions-list](https://learn.microsoft.com/azure/role-based-access-control/role-definitions-list)
  * Cmdlet refs:

    * `Get-AzRoleAssignment`: [https://learn.microsoft.com/powershell/module/az.resources/get-azroleassignment](https://learn.microsoft.com/powershell/module/az.resources/get-azroleassignment)
    * `Get-AzRoleDefinition`: [https://learn.microsoft.com/powershell/module/az.resources/get-azroledefinition](https://learn.microsoft.com/powershell/module/az.resources/get-azroledefinition)
    * `Get-AzManagementGroup`: [https://learn.microsoft.com/powershell/module/az.resources/get-azmanagementgroup](https://learn.microsoft.com/powershell/module/az.resources/get-azmanagementgroup)
