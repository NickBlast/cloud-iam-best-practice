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
