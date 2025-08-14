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

# 🧠 IAM Architecture Brain Dump  
## Section 1 – Current State Overview (Refined)

---

### ☁️ Cloud Platforms in Use
- **AWS**
- **Azure / Microsoft Entra**
- **GCP** (small-scale environment)

---

### 🔐 IAM Tools & Infrastructure
- **SailPoint IdentityIQ (IDQ)**:
  - Governs identity lifecycle and role memberships
  - Manages AWS IAM role access via Active Directory (AD) groups
  - Controls Azure Entra and GCP access via AD group mappings
- **Okta**:
  - Main IdP for **Azure**, **Entra**, and **GCP**
- **Ping Identity**:
  - SAML-based federation specifically for **AWS console login**
- **Active Directory**:
  - On-prem or hybrid-synced to Entra
  - Central authority for group-based access
- **ServiceNow**:
  - Manual request/approval system for IAM tasks (Azure/Entra and CyberArk)
  - Used for onboarding service principals, application registrations, and secrets

---

### 🔑 Authentication & Federation
- **AWS**:  
  - Console access via **SAML federation with Ping**  
  - Role assumption based on **AD group mapping**
- **Azure/Entra & GCP**:  
  - Authenticated through **Okta**
- **Federation is split** across multiple IdPs—**Ping (AWS)** and **Okta (Azure/GCP)**

---

### 🧰 Infrastructure as Code (IaC) Usage
- **AWS**:
  - IAM roles, policies, trust relationships, and service accounts are **Terraform-managed**
  - Developer-driven model: access change requests made via PRs → reviewed by IAM → deployed
  - Multi-account setup with **environmental segmentation**:
    - Each application typically has 4 dedicated AWS accounts:
      - **Dev**
      - **QA**
      - **PreProd**
      - **Prod**
  - A major **AWS implementation revamp** is starting:
    - New **landing zone** design in early stages
    - Migration strategy, application targeting, and phased rollout are **not yet fully defined**
- **Azure / Entra**:
  - Currently manually managed (service principals, app registrations)
  - Provisioning performed by IAM via ServiceNow
  - A **new Azure landing zone** is in development
    - Goal: expand **VM-hosted solutions** into Azure over time
    - No Terraform/IaC in place yet, but planned
- **GCP**:
  - Small footprint
  - Terraform-managed
  - IAM group-based access tied to AD

---

### 🔒 Secrets Management
- **AWS Secrets Manager**:
  - Scoped only to AWS workloads
- **CyberArk**:
  - Used for broader secrets management across on-prem and hybrid
  - No integration with cloud platforms
  - Manual object onboarding via ServiceNow tickets
- No centralized secrets strategy across clouds  
  → Secrets lifecycle management is **fragmented and manual-heavy**

---

### 📓 Documentation & Workflow
- **Confluence**:
  - Source of documentation for all cloud environments and IAM architecture
- **Jira (Agile Workflow)**:
  - Engineering tickets for IAM changes, IaC deployment, service onboarding
  - Epics may span access automation, Terraform modules, or cloud integrations

---

### ⚠️ Current Pain Points / Observations
- **Split Identity Providers**:
  - Ping + Okta adds complexity to auditability, trust chaining, and SSO UX
- **Azure Lagging in Automation**:
  - No IaC = manual risk, slower provisioning, poor visibility
- **CyberArk Isolated**:
  - No cloud-native integration or automation; only ticket-based flow
- **IAM Model Is Split Across Clouds**:
  - AWS = dev-led and codified  
  - Azure = IT-led and manual  
  - GCP = small and consistent but not scaled
- **IAM Review Workflow for AWS**:
  - Manual PR reviews by IAM team—scaling risk as cloud footprint grows
- **In-Flight Architectural Shifts**:
  - **AWS revamp**: no clear migration strategy or scope yet
  - **Azure landing zone**: in buildout phase, intended for VM workloads, not yet production-ready

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

# 🧠 IAM Architecture Brain Dump  
## Section 3 – IAM Models Per Cloud

---

### ✅ AWS IAM Model

**Account Structure:**
- Environment-based multi-account strategy:
  - Each application gets 4 accounts: `Dev`, `QA`, `PreProd`, `Prod`
- Account boundaries are used for:
  - Environment isolation
  - Risk containment
  - Access boundary enforcement

**IAM Design & Access Patterns:**
- **Users assume roles via SAML federation with Ping Identity**
  - AWS users must be onboarded into **Ping** to access AWS roles
- **Roles are tied to Active Directory groups**, managed and certified through **SailPoint**
- **Access Types**:
  - Team roles are created with **various levels of access**
  - Many roles are **privileged** and include **write or administrative access** within the AWS console
- **Access change workflow**:
  - Developers submit PRs to a **central IAM Terraform repo**
  - PRs are reviewed by both the **IAM team** and the **CyberSecurity team**
  - Requires **two-stage approval** before Terraform deployment
- **Service Accounts**:
  - Created and maintained via **Infrastructure as Code**
  - Secrets stored in **AWS Secrets Manager**
  - **Secrets and access keys are manually synchronized to CyberArk**
- No **Just-in-Time (JIT)** or temporary elevation roles currently exist (only static assumption roles)

**Tooling & Provisioning:**
- Terraform is used for all IAM provisioning:
  - IAM roles, policies, trust relationships, service accounts

**Known Gaps:**
- Role sprawl risk over time (no telemetry-based downsizing)
- No JIT or automated elevation access
- CyberArk sync is entirely manual
- New **AWS landing zone** is in early planning; migration strategy is undefined

---

### ✅ Azure / Entra IAM Model

**Scope Hierarchy in Use:**
- Follows Microsoft’s scope levels:
  - Tenant Root (Management Group) → Subscription → Resource Group → Resource
- Role assignments are made at multiple scopes depending on use case
- Entra ID (Azure AD) is the primary identity authority for Azure access

**IAM Design & Access Patterns:**
- User authentication via **Okta**
- Role assignments and group membership tied to **AD groups via SailPoint**
- Azure roles are manually assigned via **ServiceNow tickets**
- **Privileged Identity Management (PIM)**:
  - **Reviewed**, but **not planned for use at this time**
- **SailPoint development is in progress** to enable **JIT access control**
  - However, JIT via SailPoint is **not expected to be deployed this year**
- Application registrations and service principals are **manually created**
- No Terraform/IaC coverage yet for Azure IAM

**Tooling & Provisioning:**
- Manual process for now, with ServiceNow approvals
- Planned IaC implementation for:
  - Service principals
  - Role assignments
  - Future SailPoint-integrated workflows

**Known Gaps:**
- No Terraform-based IAM provisioning yet
- No integration with CyberArk for Azure secrets
- High reliance on ticket-based manual processes (access drift risk)
- Azure landing zone is under active construction, not fully operational

---

### ✅ GCP IAM Model

**Environment & Scale:**
- Small cloud footprint
- Primarily used for **support ticket handling** tied to **a single on-prem application**
- Very **few users or services** operate within GCP

**IAM Design & Access Patterns:**
- User authentication via **Okta**
- Access is managed through **Active Directory group membership**
- **Group-role mappings are governed directly in GCP**
- IAM **role bindings are defined via Terraform**

**Tooling & Provisioning:**
- **Terraform** is used for provisioning:
  - IAM roles
  - Role bindings
  - Service accounts

**Known Gaps:**
- No integration with **CyberArk** for secrets storage or syncing
- No **centralized access review process**
  - Ad hoc manual reporting is used for audits
- No **Just-in-Time (JIT)** access model in place
- **Cloud-native identity services** (e.g., GCP Workload Identity Federation) are **not currently used**

# 🧠 IAM Architecture Brain Dump  
## Section 4 – Identity Source of Truth & Federation Mapping

---

### 🧬 Part A: Identity Source of Truth

#### Primary Identity System:
- **Active Directory (on-prem)** is the **authoritative source of identity truth**
  - Users are created directly in AD
  - AD group memberships drive access across **AWS**, **Azure/Entra**, and **GCP**

#### SailPoint IdentityIQ:
- Manages the full **identity lifecycle**:
  - Create, update, disable
- Governs **AD group membership** for **all AD-based access**, including cloud platform role mapping
- Integrates with:
  - **ServiceNow**
  - **AWS**
  - **Azure / Entra**
  - **GCP**
- **Future-state goal**:
  - Expand SailPoint governance to support **Just-in-Time (JIT)** access models

#### HRIS (Ultipro):
- Source of **employee lifecycle triggers**
  - **New hire** → AD account creation
  - **Termination** → triggers offboarding and account deactivation
- Connected to SailPoint via **SCIM** or equivalent provisioning sync

#### ServiceNow:
- Operational **front-end for manual provisioning tasks**
  - Especially used in **Azure/Entra**
- Tracks **application and service ownership** through CMDB
- Facilitates **approval workflows** for:
  - AD group assignments
  - Secrets provisioning
  - Application onboarding
  - Access certification requests

---

### 🌐 Part B: Federation Architecture

#### Federation Map:

| Platform        | Identity Provider (IdP) | Federation Protocol | Notes |
|----------------|--------------------------|---------------------|-------|
| **AWS**        | Ping Identity             | SAML 2.0            | Role assumption; mapped to AD groups via SailPoint |
| **Azure/Entra**| Okta                      | OIDC + SAML         | Users log in via Okta → mapped to Entra ID objects |
| **GCP**        | Okta                      | SAML 2.0            | Auth via Okta; access via AD group mapping |

#### Notes:
- Federation is **split between Ping and Okta**
  - Ping handles **AWS console access**
  - Okta handles **Azure/Entra and GCP**
- Long-term vision may include:
  - Consolidation to a single IdP
  - Federation with workload identities (OIDC to service accounts)
  - Support for external identities (vendors, contractors, B2B)

#### Known Gaps:
- Ping and Okta dual usage adds **audit complexity**
- No current federation with service accounts (e.g., AWS ↔ GCP or OIDC roles)
- No external identity federation (e.g., B2B/B2C guest access policies)

# 🧠 IAM Architecture Brain Dump  
## Section 5 – Authentication & Federation Protocols

---

### 🔐 User Authentication Flows

#### AWS
- **Identity Provider:** Ping Identity  
- **Protocol:** SAML 2.0 federation  
- **Flow:**
  1. User authenticates with **Ping Identity**
  2. SAML assertion includes group claim(s)
  3. AWS maps group claim to an IAM Role via trust policy
  4. User assumes role via temporary credentials (STS)
- **Access Path:**  
  AWS Console → SAML Login via Ping → Role Assumption

#### Azure / Entra
- **Identity Provider:** Okta  
- **Protocol:** OIDC + SAML  
- **Flow:**
  1. User authenticates to Okta
  2. Okta issues OIDC token or SAML assertion
  3. Entra ID processes and maps to Azure user object
  4. Access governed by RBAC role assignments
- **Access Path:**  
  Azure Portal or CLI → Okta Login → Token → Entra ID → Role

#### GCP
- **Identity Provider:** Okta  
- **Protocol:** SAML 2.0  
- **Flow:**
  1. User logs into Okta
  2. Okta delivers SAML assertion to GCP
  3. Role access is granted based on mapped AD group bindings
- **Access Path:**  
  GCP Console → SAML via Okta → Role binding → Permissions

---

### 🔐 Machine/Service Authentication Flows

#### AWS
- Service accounts authenticate via:
  - **Access keys**
  - **IAM instance profiles (EC2)**
  - **IAM roles for Lambda / ECS**
- No current use of **IAM Roles Anywhere** or **OIDC federated workloads**
- Secrets stored in AWS Secrets Manager, with **manual CyberArk sync**

#### Azure / Entra
- App registrations use:
  - **Client ID + secret** or **certificate-based auth**
- Service principals are used for workload access
- No current automation for key rotation or secrets sync to CyberArk

#### GCP
- Service accounts authenticate with:
  - **JSON keys**
  - Bound roles via IAM bindings in Terraform
- No current use of **Workload Identity Federation**
- Secrets are not stored in a central vault or synchronized to CyberArk

---

### 🔐 MFA Policy & Enforcement

| Platform | MFA Enforcement | Method         | Gaps                      |
|----------|------------------|----------------|---------------------------|
| AWS      | Enforced via Ping| Ping MFA stack | Ping config not natively visible in AWS CloudTrail |
| Azure    | Enforced via Okta| Okta MFA       | Relies on Okta policy, not native Entra enforcement |
| GCP      | Enforced via Okta| Okta MFA       | Not integrated into GCP IAM policy views |

- No **platform-native MFA enforcement** (e.g., AWS IAM policies, Entra CA policies) is configured—MFA is enforced upstream via IdPs.
- **Visibility into MFA events is fragmented** and not easily audit-able across platforms
- Long-term need for:
  - **MFA event logging in Splunk**
  - Conditional Access insights
  - Federated MFA assertion chaining support

---

### ⚠️ Known Gaps & Federation Constraints

- Dual IdP strategy (Ping + Okta) complicates:
  - Access auditability
  - Unified MFA policy enforcement
  - Federation drift detection
- No consistent method to:
  - Track token lifetime
  - Validate identity assertion format across platforms
- No service-to-service identity federation (e.g., OIDC trust between AWS ↔ GCP)
- No passwordless or FIDO2-based login workflows implemented
- Service account credentials are not scoped with time-bound or scoped tokens (static keys/certs are used)

# 🧠 IAM Architecture Brain Dump  
## Section 6 – Authorization Strategy

---

### 🧩 Authorization Models in Use

#### ✅ RBAC (Role-Based Access Control)
- Core authorization model across **all cloud platforms**
- Access is granted via **roles**, which are:
  - Mapped to **AD groups**
  - Managed through **SailPoint**
  - Associated with **predefined permission sets** per environment or app
- Roles are often application- or team-specific:
  - `Team-App1-Dev-ReadOnly`, `Team-App2-Prod-Admin`

#### 🌱 ABAC (Attribute-Based Access Control)
- **Not currently implemented**
- **Not yet explored in depth**, but recognized as a **potential future-state model**
- Future-state use cases may include:
  - Workload-based identity enforcement
  - Tag-based resource-level trust boundaries
  - Attribute-driven access to secrets, databases, or cloud-native services

#### ⚙️ Scope-Based Access in Azure/Entra
- Azure uses **scoped RBAC**:
  - Access assigned at: **Tenant → Subscription → Resource Group → Resource**
- Role assignment scope depends on:
  - App ownership
  - Environment criticality
  - Manual review via ServiceNow

---

### 🔗 Role Assignment & Governance

- **SailPoint** governs **AD group membership** for access control
  - Drives access across **AWS, Azure, and GCP**
- **Group membership is role-linked**:
  - E.g., `aws-dev-readonly`, `azure-prod-contributor`
- Access control flows:
  - **AWS**: PR-based access via IAM Terraform repo
  - **Azure**: Ticket-based via ServiceNow
- **ServiceNow** handles approvals and CMDB mapping

---

### 🏷️ Metadata & Tag-Based Strategies

- IAM resources and policies include the following metadata:
  - `application_name`
  - `project_id` *(optional)*
  - `source_repo` *(optional)*
  - `environment` (e.g., dev, QA, prod)
  - `owner` (linked to CMDB or business contact)
- Tagging standards enforce:
  - Application-to-resource mapping
  - Owner-driven access certifications
  - Future-state automation enablement
  - Metrics collection and analysis

---

### 🔐 Privileged Role Access

- Privileged roles (write, modify, admin):
  - Are tightly scoped
  - Require **manual or PR-based approval**
  - Are not granted by default
- No current **Just-in-Time (JIT)** access model (planned via SailPoint)
- Annual reviews validate privileged access compliance

---

### 📉 Role Review & Reduction Strategy

- Role sprawl is actively recognized
- Strategy includes:
  - Usage telemetry from **AWS Access Analyzer**, **Azure logs**, **GCP audit logs**
  - Annual access review cycles
  - Manual recertification via **SailPoint** and **ServiceNow**

---

### ⚠️ Known Gaps in Authorization Strategy

- No dynamic (ABAC-style) access enforcement today
- Role naming conventions and scopes vary across clouds
- No CI/CD policy-as-code enforcement for role structure
- Over-provisioned roles are not flagged automatically
- Resource tags are **not yet tied to IAM enforcement**
- Group-to-role lifecycle is managed manually

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

# 🧠 IAM Architecture Brain Dump  
## Section 8 – Auditing & Monitoring

---

### 📦 Log Aggregation & Visibility

| Platform | Log Source                         | Centralized In? | Notes                                               |
|----------|-------------------------------------|------------------|-----------------------------------------------------|
| **AWS**  | CloudTrail, CloudWatch, IAM events | ✅ Splunk Cloud   | Includes role assumptions, STS activity, key usage  |
| **Azure**| Entra ID Logs, Azure Activity Logs | ✅ Splunk Cloud   | Includes sign-in events, directory changes          |
| **GCP**  | Audit Logs, IAM activity logs       | ✅ Splunk Cloud   | Logs role bindings, service account usage           |

- **Splunk Cloud** serves as the **central log aggregation and search platform**
- Used for:
  - IAM access traceability
  - Historical analysis
  - Ad hoc audit response
- **IAM-specific dashboards** are planned but not yet standardized

---

### 🔔 Alerting & Monitoring Use Cases

- **Privileged Role Assumption**
  - Alerts on STS usage in AWS (role assumption)
  - Manual reviews for Azure and GCP privileged role assignments
- **Secrets Usage or Access Key Events**
  - AWS Secrets Manager logs usage; monitored via Splunk
  - CyberArk lacks native event integration—manual logging only
- **Group Membership Changes**
  - SailPoint may emit provisioning logs to Splunk
  - No direct alerting yet on "high-risk" group changes

---

### 🔍 Drift Detection & Reconciliation

| Area         | Detection Method       | Notes                                                     |
|--------------|------------------------|-----------------------------------------------------------|
| **AWS IAM**  | Terraform + PR review  | Manual validation during PR; no continuous detection       |
| **Azure IAM**| No tooling yet         | Role assignments managed manually—no drift alerts         |
| **GCP IAM**  | Terraform only         | Drift may occur with direct changes outside IaC           |

- No real-time detection of IAM policy drift across platforms
- Opportunity to integrate **policy diff tools** (e.g., Terraform plan diff + approval gates)
- **Veza onboarding** may support IAM visibility and drift reconciliation

---

### 🔐 Access Review Monitoring

- **Access Certifications**:
  - Driven via **SailPoint** review workflows (user/group)
  - Manual campaign requests submitted through **ServiceNow**
- **Privileged Access Reviews**:
  - Annual policy and role recertification
  - Results logged and auditable in Splunk or certification tools
- No continuous monitoring of low-usage or excessive-privilege accounts

---

### ⚠️ Known Gaps & Monitoring Limitations

| Gap Area                     | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| **CyberArk audit integration** | No event stream for secrets access, no Splunk integration                  |
| **Privileged access visibility** | No real-time alerts on high-privilege usage in Azure or GCP                |
| **Drift detection**          | No continuous reconciliation between declared state (IaC) and deployed state |
| **MFA enforcement audit**    | MFA policy logs reside in IdPs (Ping/Okta), not cloud-native logging layers |
| **IAM event dashboards**     | Splunk ingestion exists, but IAM-specific dashboards are ad hoc or missing   |

# 🧠 IAM Architecture Brain Dump  
## Section 9 – Account & Tenant Structure

---

### 🧱 AWS Account Structure

- Follows a **multi-account model**, with segmentation by both **application** and **environment**
- Each business application is typically assigned **four AWS accounts**:
  - `Dev`
  - `QA`
  - `PreProd`
  - `Prod`
- Accounts are used to:
  - Isolate environments for security and blast radius containment
  - Scope IAM roles and permissions based on environment sensitivity
  - Separate billing and resource tags
- **Landing Zone Revamp**:
  - New AWS Landing Zone is being built
  - Migration and consolidation planning is underway, but not yet defined
  - Future-state may introduce centralized shared services accounts (e.g., networking, logging, IAM)

---

### 🧱 Azure Tenant & Subscription Structure

- Azure/Entra follows Microsoft’s **scope hierarchy**:
  - **Tenant Root (Management Group)** → **Subscription** → **Resource Group** → **Resource**
- There are **multiple subscriptions** organized by environment:
  - Separate subscriptions for **production** and **non-production**
- **Resource Groups**:
  - Used as the primary **scoping unit for services**
  - Help isolate workloads, manage role assignments, and enforce tagging policies
- Access is scoped depending on:
  - Environment sensitivity (e.g., prod vs dev)
  - Application ownership
- Azure Landing Zone is being expanded to support:
  - Cloud-native onboarding
  - VM hosting
  - Standardized IAM governance via Terraform (planned)

---

### 🧱 GCP Project Structure

- GCP usage is limited to **a single project** supporting **on-premise ticketing integration**
- Access is scoped via:
  - Project-level IAM roles
  - Terraform-defined bindings
- Role definitions are tied to AD groups through SailPoint governance
- No organization-wide GCP IAM model or folder hierarchy is in use
- Resource tagging is minimal due to the limited footprint

---

### 🧾 Naming Standards & Tagging Enforcement

- IAM resources and cloud objects follow a **structured naming standard**, including:
  - `application_name`
  - `environment` (dev, qa, prod)
  - `project_id` *(optional)*
  - `source_repo` *(optional)*
- Tags are enforced for:
  - **CMDB mapping**
  - **IAM ownership assignment**
  - **Audit trail generation**
  - **Future policy-as-code enablement**
- Enforcement is manual today; future-state plans include:
  - Terraform pre-commit hooks
  - Policy-as-code drift detection (OPA, Sentinel, or Conftest)

# 🧠 IAM Architecture Brain Dump  
## Section 10 – Future Plans & Experiments

---

### 🧪 In-Flight Initiatives

| Initiative                              | Status             | Target Outcome                                               |
|----------------------------------------|---------------------|--------------------------------------------------------------|
| **AWS Landing Zone Revamp**            | Design phase        | Standardized account boundaries, shared services, IaC baseline |
| **Azure Landing Zone Buildout**        | Early rollout       | Subscription controls, VM onboarding, future Terraform integration |
| **Veza Onboarding**                    | Planned this year   | Visibility into IAM drift, privilege audit, and cloud identity posture |
| **SailPoint JIT Access Support**       | Under development   | Just-in-time role elevation; access by approval + duration controls |
| **Central IAM Metrics Dashboard**      | In progress         | Unified view of IAM objects, owners, tagging, and compliance posture |
| **Ping → Okta AWS Migration**          | Scoped              | Move AWS federation from Ping to Okta to simplify IdP landscape |
| **Ping Certificate Refresh**           | Scheduled           | Avoid disruption during SAML token signing and renewals     |
| **Operations Process Development**     | Active              | Codify IAM tasks, approvals, runbooks, and response playbooks |

---

### 🔭 Strategic Future-State Goals

#### ✅ **Unified Access Governance Across Clouds**
- One approval path via SailPoint or ServiceNow
- Standardized roles, metadata, and naming across AWS, Azure, and GCP
- Cross-cloud drift detection and role certification

#### ✅ **JIT + Approval-Based Access Model**
- Reduce static privileged access
- Enforce time-boxed elevation with:
  - Approval workflows
  - Duration limits
  - Post-access revocation
- Starts with SailPoint + Azure, later extended to AWS/GCP

#### ✅ **Automated Secrets Management Lifecycle**
- Automatically sync AWS, Azure, and GCP secrets to CyberArk
- Provision and rotate secrets via Terraform
- Monitor usage and trigger alerts on stale or unused credentials

#### ✅ **Policy-as-Code Enforcement**
- Integrate validation checks into Terraform pipelines:
  - Tag compliance
  - Role naming patterns
  - Permission scope constraints
- Use tools like:
  - OPA / Rego
  - Conftest
  - TFSec
  - Checkov

#### ✅ **Telemetry-Driven Least Privilege**
- Capture actual permission usage across cloud platforms
- Flag unused or excessive roles
- Feed into SailPoint campaigns or automatic PR reduction

#### ✅ **Automation of Resource Compliance**
- Automatically validate tag presence, ownership linkage, and policy configuration
- Generate compliance dashboards and non-compliant resource alerts
- Integrate into Terraform CI/CD and Splunk reports

---

### 🧪 Research & Proof of Concept (PoC) Areas

- **Passwordless / FIDO2 Authentication**  
  → Evaluate impact of phish-resistant auth for internal IAM workflows

- **Cross-Cloud Workload Federation**  
  → OIDC federation from Entra ID to AWS  
  → IAM Roles Anywhere or STS assumption from GCP

- **Service Account Expiration + Alerting**  
  → Expiry metadata, automatic notifications, audit trail of renewals

- **IAM Drift Detection as a Service**  
  → Track changes outside Terraform; flag in Slack/Jira/Splunk

- **Behavioral IAM Scoring**  
  → Feed user + service account behavior into risk scoring model for reviews
