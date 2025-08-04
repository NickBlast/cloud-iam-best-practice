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
