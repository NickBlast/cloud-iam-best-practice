# 📊 IAM Research Initiative – Multi-Cloud Financial Institution

This repository documents a deep research initiative to evaluate and evolve IAM strategy for a hybrid multi-cloud environment (AWS, Azure/Entra, GCP) in a highly regulated financial enterprise.

---

## 📥 Research Objective

To identify best practices, tooling, staffing patterns, and emerging trends in Identity & Access Management as applied to **banking and financial services**, aligned with **FFIEC CAT**, **NIST 800-53**, and **CSA STAR** controls.

---

## 📌 Scope

### Cloud Platforms:
- AWS (multi-account, Terraform-managed, Ping federation)
- Azure/Entra (manual IAM with IaC roadmap, Okta federation)
- GCP (single project, AD group access, Terraform-defined)

### IAM Tooling:
- SailPoint IdentityIQ (group governance, access reviews)
- Ping Identity & Okta (federation, MFA)
- CyberArk & AWS Secrets Manager (manual secrets lifecycle)
- Splunk Cloud (log aggregation)
- Veza (planned posture observability)

---

## 🔍 Research Areas

1. **Best Practice IAM Design for Multi-Cloud Financial Environments**
2. **Tooling Evaluation**
3. **Team Design & Staffing Strategy**
4. **IAM Engineer Day-to-Day Responsibilities**
5. **Emerging Technologies & Sector Trends**
6. **Build vs Buy: Reporting, Drift Detection, IAM Metrics**
7. **IAM Engineers in a DevSecOps Model**

---

## 📊 Live Tracker

See [`IAM Research Tracking Sheet`](./IAM_Research_Tracking_Sheet.xlsx) for:
- Findings
- Recommended actions
- Tool mentions
- Financial-sector relevance
- Status tracking

---

## 📎 Outputs

All deep research results will be linked here by section, along with documented takeaways and decisions.

---

## 🧩 Related Documentation

- [`IAM Architecture Index`](./IAM_Architecture_Index.md)
- [`IAM Strategy Sections 1–10`](./architecture-docs/)
- [Splunk Dashboards (internal)](#)
- [Terraform IAM Modules (GitLab)](#)

---

## 📅 Review Cadence

- Updates reviewed weekly by IAM leadership
- Strategy iterations logged quarterly
- All findings tagged by relevance: `Compliance`, `Automation`, `Tooling`, `DevSecOps`, `JIT`, `Secrets`, `Governance`

---

## 🛠 Scripts Quickstart

This repository includes enterprise-grade IAM reporting scripts for Azure/Entra ID RBAC analysis.

### 📁 Directory Structure
```
/scripts/
├── common/                 # Shared logging libraries
│   ├── python/
│   └── powershell/
├── azure/                  # Azure RBAC exporters
│   ├── python/
│   └── powershell/
├── aws/                    # AWS placeholders
└── gcp/                    # GCP placeholders
```

### 🚀 Quick Start Examples

**PowerShell (Windows/Linux/macOS):**
```powershell
# Export specific subscriptions with redaction
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -Subscriptions "sub1,sub2" -Redact

# Discover subscriptions with large tenant confirmation
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -DiscoverSubscriptions -ConfirmLargeScan

# Traverse management groups without principal resolution (faster)
.\scripts\azure\powershell\Export-RbacRolesAndAssignments.ps1 -TraverseManagementGroups -NoResolvePrincipals
```

**Python (Cross-platform):**
```bash
# Export specific subscriptions with redaction
python scripts/azure/python/export_rbac_roles_and_assignments.py --subscriptions sub1,sub2 --redact

# Discover subscriptions with large tenant confirmation
python scripts/azure/python/export_rbac_roles_and_assignments.py --discover-subscriptions --confirm-large-scan

# Include resource-level assignments (use with --limit for testing)
python scripts/azure/python/export_rbac_roles_and_assignments.py --subscriptions sub1 --include-resources --limit 5
```

### ⚠️ Large Tenant Safety

**READ THIS FIRST IF YOU HAVE >25 SUBSCRIPTIONS OR >200 RESOURCE GROUPS**

Safety rails trigger automatically. Add `--confirm-large-scan` / `-ConfirmLargeScan` to proceed:
```bash
python scripts/azure/python/export_rbac_roles_and_assignments.py --discover-subscriptions --confirm-large-scan
```

### 📤 Output Locations

**Default Structure:**
```
./output/azure/export_rbac_roles_and_assignments_{YYYYMMDD_HHMMSS}/
├── role_definitions.csv           # Role definitions export
├── role_assignments.csv           # Merged role assignments
├── role_assignments.xlsx          # Excel format (if modules available)
├── role_assignments.md            # Markdown table (limited rows)
├── role_assignments_{SUBID}.csv   # Per-subscription files
├── role_assignments_{SUBID}.xlsx  # Per-subscription Excel
└── index.json                     # Artifact inventory
```

**Logs:**
```
./logs/{YYYYMMDD}/
├── azure_export_rbac_roles_and_assignments_{runId}.log      # Human-readable
├── azure_export_rbac_roles_and_assignments_{runId}.jsonl    # Structured JSON
└── azure_export_rbac_roles_and_assignments_{runId}_summary.json
```

### 📚 Documentation

- **Azure Export Runbook**: `docs/runbooks/azure-export-rbac.md`
- **Troubleshooting Guide**: `docs/runbooks/common-troubleshooting.md`
- **Confluence Integration**: `docs/runbooks/how-to-copy-into-confluence.md`
- **Logging Schema**: `docs/design/logging-schema.md`

### 🛡 Security & Compliance

- **SSO Only**: No stored secrets, no app registrations
- **Read-Only**: Safe mode enabled by default
- **Redaction**: `--redact` masks UPNs/AppIds for sharing
- **Least Privilege**: Scope control with subscription filtering
- **No PII Exfil**: Outputs never contain tokens or passwords

### 🏃 Exit Codes

- **0**: Success - All data exported without errors
- **1**: Failure - Critical errors prevented completion  
- **2**: Partial - Completed with warnings or skipped scopes

Check summary JSON for detailed results.

---
*This README is part of the Cloud IAM Best Practice repository. Last updated: 2025*
