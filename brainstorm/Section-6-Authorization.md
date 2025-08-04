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
