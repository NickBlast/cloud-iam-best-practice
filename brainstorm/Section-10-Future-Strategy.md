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
