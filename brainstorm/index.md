# 🧠 IAM Architecture Index – Multi-Cloud Identity Strategy

This index serves as the top-level entry point for the organization's IAM architecture plan across AWS, Azure/Entra, and GCP.  
It outlines the current state, strategic goals, compliance mappings, and innovation roadmap for cloud identity and access management.

---

## 🗂️ Index of Sections

### 1. [Current State Overview](Section-1-Current-State.md)
Summary of platforms, IAM tools, authentication flows, provisioning models, and known gaps.

### 2. [IAM Architecture Objectives](Section-2-Architecture-Objectives.md)
Defines the north star: least privilege enforcement, SailPoint front-end, secrets governance, IaC coverage, and auditability goals.

### 3. [Cloud IAM Models](Section-3-Cloud-IAM-Models.md)
Per-platform breakdown:
- AWS: Multi-account RBAC via Ping + IaC
- Azure/Entra: Scoped access, manual provisioning
- GCP: Single-project IaC governance

### 4. [Identity Source of Truth & Federation](Section-4-Identity-Federation.md)
Maps how identities are created, synchronized, and federated across:
- AD (authoritative)
- SailPoint (lifecycle + groups)
- Ping + Okta (IdPs)

### 5. [Authentication & Federation Protocols](Section-5-Auth-Protocols.md)
Details all SAML/OIDC flows, MFA methods, service auth patterns, and known federation gaps.

### 6. [Authorization Strategy](Section-6-Authorization.md)
Covers RBAC usage, ABAC targets, tagging models, role approval flow, and privileged access governance.

### 7. [Compliance Requirements](Section-7-Compliance.md)
Control mappings to:
- CSA STAR
- NIST 800-53
- FFIEC CAT  
Highlights audit readiness practices and known gaps.

### 8. [Auditing & Monitoring](Section-8-Monitoring.md)
Describes log aggregation (Splunk), privileged usage alerting, drift detection gaps, and review cadences.

### 9. [Account & Tenant Structure](Section-9-Tenant-Structure.md)
Explains cloud boundary models:
- AWS: App/env accounts
- Azure: Prod/non-prod subscriptions + scoped RGs
- GCP: Single-project setup

### 10. [Future Plans & Experiments](Section-10-Future-Strategy.md)
Covers:
- In-flight projects (Veza, JIT, AWS LZ)
- Strategic goals (JIT, secrets, PoC federation)
- Research areas (passwordless, service identity expiration, telemetry scoring)

---

## 🧭 Summary Tags
`Least Privilege` · `RBAC` · `JIT Access` · `Federation` · `Compliance` · `Secrets Management` · `IaC` · `Telemetry` · `CMDB` · `MFA` · `Tagging` · `Audit Readiness` · `Policy-as-Code`

---

## 📊 Suggested Status Tracker (Optional)

| Section | Last Reviewed | Owner     | Status       | Notes                             |
|---------|----------------|-----------|--------------|-----------------------------------|
| 1       | TBD            | IAM Lead  | ✅ Finalized |                                   |
| 2       | TBD            | Arch Team | ✅ Finalized |                                   |
| 3       | TBD            | IAM Team  | ✅ Finalized |                                   |
| 4       | TBD            | IAM / AD  | ✅ Finalized |                                   |
| 5       | TBD            | Security  | ✅ Finalized | MFA gaps logged                   |
| 6       | TBD            | Governance| ✅ Finalized | ABAC future-state noted           |
| 7       | TBD            | Compliance| ✅ Finalized | Supports CSA, NIST, FFIEC         |
| 8       | TBD            | SecOps    | ✅ Finalized | Dashboards need maturing          |
| 9       | TBD            | Cloud Team| ✅ Finalized | Azure scopes clarified            |
| 10      | TBD            | Strategy  | ✅ Finalized | Reviewed quarterly for updates    |

---

## 🧩 Integration Links (Optional)
- [Splunk IAM Dashboard Prototype](#)
- [ServiceNow Access Workflow Docs](#)
- [Terraform IAM Repo](#)
- [SailPoint Access Certification Templates](#)

