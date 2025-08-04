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
