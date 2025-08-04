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
