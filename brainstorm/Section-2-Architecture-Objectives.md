# ✅ IAM Architecture Brain Dump  
## Section 2 – Architecture Objectives

---

### 🔭 1. Vision of Success
- All cloud access is scoped to **least privilege by default**.
- **Read-only access** is broadly available; **write and privileged access** is granted via:
  - Role-based RBAC assignments, or
  - **Just-in-Time (JIT)** access with:
    - Time-bounded elevation
    - Explicit approval workflow
- **SailPoint** is the authoritative **front-end for access requests** across platforms.
- **CyberArk** is the universal store for all **service account secrets and access keys** across cloud platforms.
- Access must be:
  - **Auditable**
  - **Explainable**
  - Aligned with **least privilege** and **separation of duties**
- IAM resources (roles, secrets, service accounts) must:
  - Follow **strict naming conventions**
  - Include metadata tags linking to **ServiceNow CMDB**
- IAM owns all aspects of IAM lifecycle: engineering, automation, governance, and IT project support.

---

### 🔒 2. Access Control Philosophy
- Core model: **RBAC baseline** + **JIT elevation** for privileged tasks
- Elevated access is:
  - **Time-bound**
  - **Approval-controlled**
  - **Audited**
- **Privileged Identity Management (PIM)** will be used in Entra/Azure for:
  - Time-based elevation
  - Approval gating
  - Justification tracking
- Full participation in:
  - **Annual user access certifications**
  - **Policy and role lifecycle reviews**
- **Azure/Entra access** respects scope hierarchy:
  - Tenant Root → Subscription → Resource Group → Resource

---

### ⚙️ 3. Lifecycle & Governance Goals
- All IAM provisioning (roles, policies, accounts) is managed via **Terraform**, except AD groups.
- Resources must:
  - Follow naming standards
  - Include **CMDB tags**
- Terraform deployments require:
  - **Two-level approvals**
  - Use of:
    - Dedicated IAM repo, or
    - Central Terraform module registry
- Diagrams and automation metadata explain:
  - Authentication/authorization flows
  - Provisioning logic
  - User/service access logic per platform

---

### 🧩 4. Policy Management & Standardization
- All clouds follow unified standards for:
  - Naming conventions
  - Tagging
  - Ownership metadata
- Data-plane IAM (e.g., RDS, Cosmos DB, BigQuery) is in-scope for:
  - Tagging
  - Lifecycle review
  - Policy compliance
- A **central IAM inventory system** captures:
  - Resource state
  - Metrics
  - Alert data
  - Compliance flags
- **Veza** is being onboarded to improve:
  - Visibility
  - Policy alignment
  - Role auditability
- **Wiz.io** is used today, but lacks identity context.
- **PowerShell reporting** exists for Entra, Azure, AWS (to be automated).

---

### 🔁 5. Auditing & Review Expectations
- Reviews are conducted:
  - **Annually for users**
  - **Annually or usage-driven** for roles/policies
- Audit expectations:
  - Access flows fully traceable
  - Privileged activity flagged
  - Onboarding/offboarding logged
- All **cloud-native logs** are centralized in **Splunk Cloud** for:
  - Event tracing
  - IAM activity auditing
  - Custom dashboarding and report generation
- IAM alerting must detect:
  - Misaligned roles
  - Excessive permissions
  - Secrets exposure or drift

---

### ⚙️ 6. Automation Goals
- Target automation areas:
  - **Access key and secret rotation**
  - **Secrets syncing with CyberArk**
  - **Provisioning CyberArk safes/objects via Terraform**
  - **CMDB mapping via auto-tagging**
  - **IAM policy compliance for data-plane services**
- Automation must include:
  - Metadata about process ownership
  - Self-validating checks
  - Modular pipeline patterns for extensibility

---

### 🧪 7. Innovation & Maturity Planning
- IAM becomes:
  - Cloud enablement partner
  - Policy gatekeeper
  - Security telemetry hub
- Future roadmap:
  - Mature Terraform registry
  - IAM-Automation-SailPoint-CyberArk convergence
  - AI-powered access reviews and suggestions
  - Unified secrets lifecycle automation
  - Cross-cloud identity federation (e.g., Entra ↔ AWS OIDC, GCP ↔ AWS federation)

---

### 🛡️ 8. Compliance Requirements
- IAM architecture must comply with:
  - **CSA STAR**
  - **NIST 800-53**
  - **FFIEC CAT**
- Controls must be:
  - Traceable
  - Auditable
  - Mapped to lifecycle, roles, approvals, and logging
- Reviews and audits must be **evidence-driven and policy-mapped**

---

### 🧱 9. Cloud-Native Architecture Alignment
- All cloud platforms adhere to their **Well-Architected Frameworks**:
  - **AWS**: Security pillar
  - **Azure**: Identity, governance, cost management
  - **GCP**: IAM, audit, resource protection
- IAM integrates with cloud-native controls for:
  - Authentication
  - Authorization
  - Secrets management
  - Resource boundary enforcement

---

### 🧼 10. Service Account Standards
- All service accounts must:
  - Be created via **IaC only**
  - Use **unique roles per service context**
  - Be mapped to CMDB ownership metadata
  - Undergo **rotation and key management**
  - Be reviewed periodically for activity and scope drift

---

### 🧠 11. Secrets Rotation & Monitoring Policy
- Secrets (including access keys, app credentials) follow:
  - **Standard rotation windows** (e.g., 60–90 days max)
  - Rotation processes built into automation pipelines
  - Alerts on stale secrets or usage outside approved scope

---

### 📉 12. Usage-Based Role Downsizing
- Role permissions are evaluated against **actual usage telemetry**
- Data sources include:
  - **AWS CloudTrail Access Analyzer**
  - **Azure Sign-In and Activity Logs**
  - **GCP IAM Audit Logs**
- Inactive permissions are flagged and tracked for removal
- Supports **progressive least privilege** through **behavioral tuning**

---

### 🧪 13. Testing & Policy-as-Code Enforcement
- All IAM module changes are subject to:
  - **Staging environment validation**
  - GitOps-based **approval gates**
  - Integration with policy linters (e.g., TFSec, Checkov)
  - Future-state: **OPA/Rego** or **Conftest** for centralized guardrails
