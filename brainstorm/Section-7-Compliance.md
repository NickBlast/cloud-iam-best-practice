# 🛡️ IAM Architecture Brain Dump  
## Section 7 – Compliance Requirements

---

### 📋 Targeted Compliance Frameworks

Your IAM architecture is expected to meet the identity-related control objectives of:

| Framework     | Scope                                                                 |
|---------------|-----------------------------------------------------------------------|
| **CSA STAR**  | Cloud-specific security maturity model                                |
| **NIST 800-53** | Fed-aligned controls for access control, audit, identity lifecycle     |
| **FFIEC CAT** | Financial-sector control expectations (access, data, monitoring)       |

---

### 🔐 IAM Control Objectives Aligned to These Frameworks

| Control Area                         | Implementation Summary                                                                 |
|-------------------------------------|-----------------------------------------------------------------------------------------|
| **Identity Lifecycle Management**   | Managed via **AD + SailPoint**; synced from **HRIS (Ultipro)**; supports create/update/disable |
| **Authentication Assurance**        | **MFA enforced** upstream via **Ping (AWS)** and **Okta (Azure, GCP)**                  |
| **Access Control & Role Governance**| RBAC via **AD groups**; governed by **SailPoint**, scoped roles per environment         |
| **Privileged Access Management**    | Elevated roles gated by **manual approvals or PRs**; reviewed annually                 |
| **Separation of Duties**            | IAM reviews PRs; CyberSecurity double-approves AWS access; ServiceNow workflows separate requesters/approvers |
| **Access Reviews / Recertification**| Annual **user access certifications** and **policy/role reviews** via SailPoint and ServiceNow |
| **Audit Logging**                   | All platform logs centralized to **Splunk Cloud**; includes user logins, provisioning activity, and secrets access logs where supported |
| **Secrets Management**              | **AWS Secrets Manager** (scoped to AWS); **CyberArk** for long-lived credentials (manually managed) |
| **CMDB Integration**                | All IAM resources tagged to **business application owners** for traceability and review accountability |

---

### ✅ Key Practices That Support Audit Readiness

- **Two-stage access approval** for privileged AWS access (IAM + CyberSecurity)
- **Tagging standards** enable CMDB linking for audit trails and access justification
- **Federated login** provides MFA via IdPs and limits password sprawl
- **SailPoint governance** aligns with control objectives for lifecycle management and certification
- **Splunk ingestion** enables real-time traceability and reporting of identity-related events

---

### ⚠️ Known Gaps / Remediation Opportunities

| Gap Area                            | Notes                                                                                  |
|-------------------------------------|-----------------------------------------------------------------------------------------|
| **MFA auditability**                | MFA enforcement is via IdPs—**not visible in cloud-native logs** (AWS, Azure, GCP)     |
| **CyberArk manual workflows**       | Secrets are synced manually—**no automated validation**, drift tracking, or lifecycle monitoring |
| **Policy-as-Code compliance guardrails** | No enforcement of tagging, role naming, or permission scope via automation pipelines  |
| **JIT access enforcement**          | Not yet implemented—planned via future **SailPoint expansion**                         |
| **Service account lifecycle**       | No expiration, alerting, or review mechanism for long-lived service account credentials |
| **ABAC-based control mapping**      | Attribute-based access control not in use—**no attribute-aligned policies** currently enforced |
