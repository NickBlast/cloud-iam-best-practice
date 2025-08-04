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
